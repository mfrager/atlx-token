// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../libraries/DataERC20.sol";
import "../../libraries/DataSubscription.sol";
import "../../libraries/AccessControlEnumerable.sol";
import "../../libraries/ReentrancyGuard.sol";
import "../../interfaces/IERC20.sol";
import "../../interfaces/IERC20Metadata.sol";
import "../../interfaces/ITokenSwap.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Token is Context, ReentrancyGuard, AccessControlEnumerable, IERC20, IERC20Metadata {

    uint constant TRANSFER_LOG_WAIT_SECONDS = 24 * 60 * 60; // 1 per day
    bytes32 public constant ERC20_TOKEN_ADMIN_ROLE = keccak256("ERC20_TOKEN_ADMIN_ROLE");
    bytes32 public constant MERCHANT_ADMIN_ROLE = keccak256("MERCHANT_ADMIN_ROLE");
    bytes32 public constant SUBSCRIPTION_ADMIN_ROLE = keccak256("SUBSCRIPTION_ADMIN_ROLE");

    /**
     * @dev Emitted when a token has moved after a certain amount of time.
     */
    event EnableMerchant(address indexed merchant);
    event DisableMerchant(address indexed merchant);
    event BalanceLog(address indexed owner, uint256 balanceNew, uint256 balancePrev, uint256 balancePrevLog, uint ts);
    event Subscription(uint128 indexed subscrId, address indexed from, address indexed to);
    event SubscriptionUpdate(uint128 indexed subscrId, bool pausable, uint8 eventType, uint256 maxBudget, uint32 timeout, uint8 period);
    event SubscriptionBill(uint128 indexed subscrId, uint128 indexed eventId, uint8 eventType, uint256 amount, uint64 timestamp, uint8 errorCode);
    event SubscriptionDelegateGranted(address indexed admin, address delegate);
    event SubscriptionDelegateRevoked(address indexed admin, address delegate);

    function setupERC20Token(string memory name_, string memory symbol_, uint256 amount_, address swapper_) external nonReentrant {
        DataERC20 storage s = DataERC20Storage.diamondStorage();
        require(!s._setupDone, "SETUP_ALREADY_DONE");
        s._setupDone = true;
        s._name = name_;
        s._symbol = symbol_;
        s._swapper = swapper_;
        address sender = _msgSender();
        s._subscriptionAdmin[sender] = true;
        s._subscriptionDelegate[sender][address(1)] = true;
        s._delegateCount[sender] = 1;
        emit SubscriptionDelegateGranted(sender, address(1));
        _setupRole(DEFAULT_ADMIN_ROLE, sender);
        _setupBans(sender);
        _setRoleAdmin(MERCHANT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(ERC20_TOKEN_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(MERCHANT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(SUBSCRIPTION_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        _setupRole(ERC20_TOKEN_ADMIN_ROLE, sender);
        _setupRole(MERCHANT_ADMIN_ROLE, sender);
        _setupRole(SUBSCRIPTION_ADMIN_ROLE, sender);
        _mint(_msgSender(), amount_);
    }

    function enableMerchant(address merchant) external nonReentrant onlyRole(MERCHANT_ADMIN_ROLE) returns (bool) {
        DataERC20 storage s = DataERC20Storage.diamondStorage();
        s._validMerchant[merchant] = true;
        emit EnableMerchant(merchant);
        return(true);
    }

    function disableMerchant(address merchant) external nonReentrant onlyRole(MERCHANT_ADMIN_ROLE) returns (bool) {
        DataERC20 storage s = DataERC20Storage.diamondStorage();
        s._validMerchant[merchant] = false;
        emit DisableMerchant(merchant);
        return(true);
    }

    function isValidMerchant(address merchant) external nonReentrant returns (bool) {
        DataERC20 storage s = DataERC20Storage.diamondStorage();
        return(s._validMerchant[merchant]);
    }

    function grantSubscriptionAdmin(address account, address delegate) external nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        DataERC20 storage s = DataERC20Storage.diamondStorage();
        s._subscriptionAdmin[account] = true;
        s._subscriptionDelegate[account][delegate] = true;
        emit SubscriptionDelegateGranted(account, delegate);
        if (s._delegateCount[account] == 0) {
            _setupRole(SUBSCRIPTION_ADMIN_ROLE, account);
        }
        s._delegateCount[account] = s._delegateCount[account] + 1;
        return(true);
    }

    function revokeSubscriptionAdmin(address account, address delegate) external nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        DataERC20 storage s = DataERC20Storage.diamondStorage();
        s._subscriptionAdmin[account] = false;
        s._subscriptionDelegate[account][delegate] = false;
        emit SubscriptionDelegateRevoked(account, delegate);
        s._delegateCount[account] = s._delegateCount[account] - 1;
        if (s._delegateCount[account] == 0) {
            revokeRole(SUBSCRIPTION_ADMIN_ROLE, account);
        }
        return(true);
    }

    function actionBatch(address account, uint8[] calldata actionList, ActionSwap[] calldata swapList, ActionSubscribe[] calldata subscribeList) external nonReentrant returns (bool) {
        notBanned();
        address sender = _msgSender();
        DataERC20 storage s = DataERC20Storage.diamondStorage();
        if (s._subscriptionAdmin[sender]) {
            require(hasRole(SUBSCRIPTION_ADMIN_ROLE, sender), "ROLE_ACCESS_DENIED");
        } else {
            require(sender == account, "ACCOUNT_ACCESS_DENIED");
        }
        uint8 swapIdx;
        uint8 subscribeIdx;
        uint8 action;
        for (uint8 actionIdx; actionIdx < actionList.length; actionIdx++) {
            action = actionList[actionIdx];
            if (action == uint8(ActionType.SWAP)) {
                _action_swap(swapList[swapIdx]);
                swapIdx++;
            } else if (action == uint8(ActionType.SUBSCRIBE)) {
                _action_subscribe(account, subscribeList[subscribeIdx]);
                subscribeIdx++;
            }
        }
        return(true);
    }

    function _action_swap(ActionSwap calldata act) internal {
        bool ok = ITokenSwap(act.swapToken).swapTokens(act.swapPairId, act.fromAccount, act.fromAccount, act.swapAmount);
        require(ok == true, "SWAP_FAILED");
    }

    function _action_subscribe(address subscriber, ActionSubscribe calldata act) internal {
        _beginSubscription(act.subscrId, subscriber, act.subscrTo, act.pausable, act.subscrSpec);
        if (act.fund) {
            SubscriptionEvent memory fund;
            fund.subscrId = act.subscrId;
            fund.eventId = act.fundId;
            fund.eventType = uint8(EventType.FUND);
            fund.amount = act.fundAmount;
            fund.thisBill = act.fundTimestamp;
            _processSubscription(fund, true);
        }
    }

    function beginSubscription(uint128 subscrId, address fromAccount, address toAccount, bool pausable, SubscriptionSpec calldata spec) external nonReentrant returns (bool) {
        notBanned();
        return _beginSubscription(subscrId, fromAccount, toAccount, pausable, spec);
    }

    function _beginSubscription(uint128 subscrId, address fromAccount, address toAccount, bool pausable, SubscriptionSpec calldata spec) internal returns (bool) {
        address sender = _msgSender();
        DataERC20 storage s = DataERC20Storage.diamondStorage();
        if (s._subscriptionAdmin[sender]) {
            require(hasRole(SUBSCRIPTION_ADMIN_ROLE, sender), "ROLE_ACCESS_DENIED");
            bool isAllowed = false;
            if (s._subscriptionDelegate[sender][address(1)]) {
                isAllowed = true;
            } else if (s._subscriptionDelegate[sender][toAccount]) {
                isAllowed = true;
            }
            require(isAllowed, "ADMIN_ACCESS_DENIED");
        } else {
            require(fromAccount == sender, "ACCESS_DENIED");
        }
        require(s._balances[fromAccount] >= 0, "ERC20_BALANCE_REQUIRED");
        require(s._validMerchant[toAccount], "INVALID_MERCHANT");
        require(s._subscriptions[subscrId].mode == 0, "DUPLICATE_SUBSCRIPTION");
        SubscriptionData storage sb = s._subscriptions[subscrId];
        sb.mode = uint8(SubscriptionMode.ACTIVE);
        sb.from = fromAccount;
        sb.to = toAccount;
        sb.pausable = pausable;
        SubscriptionSpec storage sp = s._subscriptionSpec[subscrId];
        sp.period = spec.period;
        sp.timeout = spec.timeout;
        sp.maxBudget = spec.maxBudget;
        emit Subscription(subscrId, fromAccount, toAccount);
        emit SubscriptionUpdate(subscrId, pausable, uint8(EventType.CREATE), spec.maxBudget, spec.timeout, spec.period);
        return (true);
    }

    function processSubscription(SubscriptionEvent calldata subscrData, bool abortOnFail) external nonReentrant onlyRole(SUBSCRIPTION_ADMIN_ROLE) returns (bool) {
        address sender = _msgSender();
        DataERC20 storage s = DataERC20Storage.diamondStorage();
        require(s._subscriptionAdmin[sender], "ADMIN_ACCESS_DENIED");
        return _processSubscription(subscrData, abortOnFail);
    }

    function processSubscriptionBatch(SubscriptionEvent[] calldata subscrList, bool abortOnFail) external nonReentrant onlyRole(SUBSCRIPTION_ADMIN_ROLE) returns (bool) {
        address sender = _msgSender();
        DataERC20 storage s = DataERC20Storage.diamondStorage();
        require(s._subscriptionAdmin[sender], "ADMIN_ACCESS_DENIED");
        bool ok;
        for (uint256 subscrIndex; subscrIndex < subscrList.length; subscrIndex++) {
            ok = _processSubscription(subscrList[subscrIndex], false);
            if (!ok && abortOnFail) {
                string memory err = string(abi.encodePacked("SUBSCRIPTION_PROCESS_ERROR:", subscrList[subscrIndex].subscrId));
                revert(err);
            }
        }
        return(true);
    }
    
    function _processSubscription(SubscriptionEvent memory subscrData, bool abortOnFail) internal returns (bool) {
        address sender = _msgSender();
        uint128 subscrId = subscrData.subscrId;
        DataERC20 storage s = DataERC20Storage.diamondStorage();
        SubscriptionData storage sd = s._subscriptions[subscrId];
        bool isAllowed = false;
        if (sender == sd.from) {
            isAllowed = true;
        } else if (s._subscriptionDelegate[sender][address(1)]) {
            isAllowed = true;
        } else if (s._subscriptionDelegate[sender][sd.to]) {
            isAllowed = true;
        }
        require(isAllowed, "ACCESS_DENIED");
        if (sd.mode == uint8(SubscriptionMode.NONE)) {
            require(abortOnFail == true, "INVALID_SUBSCRIPTION");
            return(false);
        }
        if (sd.mode == uint8(SubscriptionMode.CANCELLED)) {
            require(abortOnFail == true, "CANCELLED_SUBSCRIPTION");
            return(false);
        }
        if (subscrData.eventType == uint8(EventType.FUND)) {
            _transfer(sd.from, sd.to, subscrData.amount);
            emit SubscriptionBill(subscrId, subscrData.eventId, subscrData.eventType, subscrData.amount, subscrData.thisBill.timestamp, uint8(EventResult.SUCCESS));
            return(true);
        }
        if (sd.mode == uint8(SubscriptionMode.PAUSED)) {
            if (subscrData.eventType == uint8(EventType.UNPAUSE)) {
                s._subscriptions[subscrId].mode = uint8(SubscriptionMode.ACTIVE);
                emit SubscriptionUpdate(subscrId, true, subscrData.eventType, 0, 0, 0);
            }
            return(true);
        } else if (subscrData.eventType == uint8(EventType.PAUSE)) {
            if (!sd.pausable) {
                if (abortOnFail) {
                    revert("SUBSCRIPTION_NOT_PAUSABLE");
                }
                return(false);
            }
            s._subscriptions[subscrId].mode = uint8(SubscriptionMode.PAUSED);
            emit SubscriptionUpdate(subscrId, true, subscrData.eventType, 0, 0, 0);
            return(true);
        } else if (subscrData.eventType == uint8(EventType.CANCEL)) {
            s._subscriptions[subscrId].mode = uint8(SubscriptionMode.CANCELLED);
            emit SubscriptionUpdate(subscrId, sd.pausable, subscrData.eventType, 0, 0, 0);
            return(true);
        }
        uint8 res = _processTerms(subscrData);
        if (res != uint8(EventResult.SUCCESS)) {
            if (abortOnFail) {
                string memory errtxt;
                if (res == uint8(EventResult.ABORT)) {
                    errtxt = "ABORT";
                } else if (res == uint8(EventResult.EXCEED_BUDGET)) {
                    errtxt = "EXCEED_BUDGET";
                } else if (res == uint8(EventResult.DUPLICATE)) {
                    errtxt = "DUPLICATE";
                } else if (res == uint8(EventResult.TIMEOUT)) {
                    errtxt = "TIMEOUT";
                }
                string memory err = string(abi.encodePacked("SUBSCRIPTION_TERMS_ERROR:", errtxt));
                revert(err);
            }
            emit SubscriptionBill(subscrId, subscrData.eventId, subscrData.eventType, subscrData.amount, subscrData.thisBill.timestamp, res);
            return(false);
        }
        // Ready to transfer
        _transfer(sd.from, sd.to, subscrData.amount);
        emit SubscriptionBill(subscrId, subscrData.eventId, subscrData.eventType, subscrData.amount, subscrData.thisBill.timestamp, res);
        return(true);
    }

    function _processTerms(SubscriptionEvent memory subscrEvent) internal returns (uint8) {
        DataERC20 storage s = DataERC20Storage.diamondStorage();        
        SubscriptionSpec memory spec = s._subscriptionSpec[subscrEvent.subscrId];
        require(spec.period != uint8(SubscriptionPeriod.INACTIVE), "INACTIVE_SUBSCRIPTION");
        if (uint128(block.timestamp) - subscrEvent.thisBill.timestamp >= spec.timeout) {
            return(uint8(EventResult.TIMEOUT));
        }
        if (spec.maxBudget > 0 && subscrEvent.amount > spec.maxBudget) {
            return(uint8(EventResult.EXCEED_BUDGET));
        }
        if (spec.period == uint8(SubscriptionPeriod.YEARLY)) {
            if (s._yearly[subscrEvent.subscrId][subscrEvent.thisBill.year]) {
                return(uint8(EventResult.DUPLICATE));
            }
            s._yearly[subscrEvent.subscrId][subscrEvent.thisBill.year] = true;
            return(uint8(EventResult.SUCCESS));
        } else if (spec.period == uint8(SubscriptionPeriod.QUARTERLY)) {
            if (s._quarterly[subscrEvent.subscrId][subscrEvent.thisBill.quarter]) {
                return(uint8(EventResult.DUPLICATE));
            }
            s._quarterly[subscrEvent.subscrId][subscrEvent.thisBill.quarter] = true;
            return(uint8(EventResult.SUCCESS));
        } else if (spec.period == uint8(SubscriptionPeriod.MONTHLY)) {
            if (s._monthly[subscrEvent.subscrId][subscrEvent.thisBill.month]) {
                return(uint8(EventResult.DUPLICATE));
            }
            s._monthly[subscrEvent.subscrId][subscrEvent.thisBill.month] = true;
            return(uint8(EventResult.SUCCESS));
        } else if (spec.period == uint8(SubscriptionPeriod.WEEKLY)) {
            if (s._weekly[subscrEvent.subscrId][subscrEvent.thisBill.week]) {
                return(uint8(EventResult.DUPLICATE));
            }
            s._weekly[subscrEvent.subscrId][subscrEvent.thisBill.week] = true;
            return(uint8(EventResult.SUCCESS));
        } else if (spec.period == uint8(SubscriptionPeriod.DAILY)) {
            if (s._daily[subscrEvent.subscrId][subscrEvent.thisBill.day]) {
                return(uint8(EventResult.DUPLICATE));
            }
            s._daily[subscrEvent.subscrId][subscrEvent.thisBill.day] = true;
            return(uint8(EventResult.SUCCESS));
        }
        return(uint8(EventResult.ABORT));
    }

    function mint(address account, uint256 amount) external nonReentrant returns (bool) {
        address sender = _msgSender();
        bool valid = false;
        DataERC20 storage s = DataERC20Storage.diamondStorage();
        if (sender == s._swapper) {
            valid = true;
        } else if (hasRole(ERC20_TOKEN_ADMIN_ROLE, sender)) {
            valid = true;
        }
        require(valid, "ACCESS_DENIED");
        _mint(account, amount);
        return(true);
    }

    function burn(address account, uint256 amount) external nonReentrant returns (bool) {
        address sender = _msgSender();
        bool valid = false;
        DataERC20 storage s = DataERC20Storage.diamondStorage();
        if (sender == s._swapper) {
            valid = true;
        } else if (hasRole(ERC20_TOKEN_ADMIN_ROLE, sender)) {
            valid = true;
        } else if (sender == account) {
            valid = true;
        }
        require(valid, "ACCESS_DENIED");
        _burn(account, amount);
        return(true);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        DataERC20 storage s = DataERC20Storage.diamondStorage();
        return s._name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        DataERC20 storage s = DataERC20Storage.diamondStorage();
        return s._symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        DataERC20 storage s = DataERC20Storage.diamondStorage();
        return s._totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        DataERC20 storage s = DataERC20Storage.diamondStorage();
        return s._balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        notBanned();
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        DataERC20 storage s = DataERC20Storage.diamondStorage();
        return s._allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        notBanned();
        _transfer(sender, recipient, amount);

        DataERC20 storage s = DataERC20Storage.diamondStorage();
        uint256 currentAllowance = s._allowances[sender][_msgSender()];

        if (currentAllowance < amount) {
            string memory err = string(abi.encodePacked("ERC20_TRANSER_EXCEEDS_ALLOWANCE:", _toString(_msgSender())));
            revert(err);
        }

        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        notBanned();
        DataERC20 storage s = DataERC20Storage.diamondStorage();
        _approve(_msgSender(), spender, s._allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        notBanned();
        DataERC20 storage s = DataERC20Storage.diamondStorage();
        uint256 currentAllowance = s._allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20_DECREASED_ALLOWANCE_BELOW_ZERO");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20_TRANSFER_FROM_ZERO_ADDRESS");
        require(recipient != address(0), "ERC20_TRANSFER_TO_ZERO_ADDRESS");
        //require(recipient != sender, "ERC20: transfer to same address as sender");

        if (recipient == sender) {
            string memory err = string(abi.encodePacked("ERC20_TRANSER_SAME_ADDRESS:", _toString(_msgSender())));
            revert(err);
        }

        DataERC20 storage s = DataERC20Storage.diamondStorage();
        uint256 senderBalance = s._balances[sender];
        uint256 recipBalance = s._balances[recipient];
        require(senderBalance >= amount, "ERC20_TRANSFER_AMOUNT_EXCEEDS_BALANCE");
        unchecked {
            s._balances[sender] = senderBalance - amount;
        }
        s._balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
        _recordTransfer(sender, senderBalance);
        _recordTransfer(recipient, recipBalance);
    }

    function _recordTransfer(address owner, uint256 prev) internal virtual {
        DataERC20 storage s = DataERC20Storage.diamondStorage();
        bool recordBalance = false;
        uint lastRecord = s._lastTransfer[owner];
        if (lastRecord == 0) {
            recordBalance = true;
        } else {
            uint diff = block.timestamp - lastRecord;
            if (diff >= TRANSFER_LOG_WAIT_SECONDS) {
                recordBalance = true;
            }
        }
        if (recordBalance) {
            uint256 bal = s._balances[owner];
            s._lastTransfer[owner] = block.timestamp;
            emit BalanceLog(owner, bal, prev, s._lastLogAmount[owner], block.timestamp);
            s._lastLogAmount[owner] = bal;
        }
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20_MINT_TO_ZERO_ADDRESS");
        DataERC20 storage s = DataERC20Storage.diamondStorage();
        uint256 prev = s._balances[account];
        s._totalSupply += amount;
        s._balances[account] += amount;
        emit Transfer(address(0), account, amount);
        emit BalanceLog(account, s._balances[account], prev, s._lastLogAmount[account], block.timestamp);
        s._lastLogAmount[account] = s._balances[account];
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20_BURN_FROM_ZERO_ADDRESS");
        DataERC20 storage s = DataERC20Storage.diamondStorage();
        uint256 accountBalance = s._balances[account];
        require(accountBalance >= amount, "ERC20_BURN_AMOUNT_EXCEEDS_BALANCE");
        uint256 prev = s._balances[account];
        unchecked {
            s._balances[account] = accountBalance - amount;
        }
        s._totalSupply -= amount;
        emit Transfer(account, address(0), amount);
        emit BalanceLog(account, s._balances[account], prev, s._lastLogAmount[account], block.timestamp);
        s._lastLogAmount[account] = s._balances[account];
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20_APPROVE_FROM_ZERO_ADDRESS");
        require(spender != address(0), "ERC20_TO_FROM_ZERO_ADDRESS");
        DataERC20 storage s = DataERC20Storage.diamondStorage();
        s._allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}
