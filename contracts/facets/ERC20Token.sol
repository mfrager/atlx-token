// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../libraries/DataERC20.sol";
import "../../libraries/DataSubscription.sol";
import "../../interfaces/IERC20.sol";
import "../../interfaces/IERC20Metadata.sol";
import "../../interfaces/ITokenSwap.sol";
import "../../interfaces/ISubscriptionTerms.sol";
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
contract ERC20Token is Context, IERC20, IERC20Metadata {

    uint constant TRANSFER_LOG_WAIT_SECONDS = 24 * 60 * 60; // 1 per day

    /**
     * @dev Emitted when a token has moved after a certain amount of time.
     */
    event BalanceLog(address indexed owner, uint256 balanceNew, uint256 balancePrev, uint256 balancePrevLog, uint ts);
    event Subscription(uint128 indexed subscrId, address indexed from, address indexed to, address terms);
    event SubscriptionUpdate(uint128 indexed subscrId, bool pausable, uint8 eventType, uint256 maxBudget, uint32 timeout, uint8 period);
    event SubscriptionBill(uint128 indexed subscrId, uint128 indexed eventId, uint8 eventType, uint256 amount, uint64 timestamp, uint8 errorCode);

    function setupERC20Token(string memory name_, string memory symbol_, uint256 amount_, address swapper_) external {
        DataERC20 storage s = DataERC20Storage.diamondStorage();
        s._name = name_;
        s._symbol = symbol_;
        s._swapper = swapper_;
        s._minter = _msgSender();
        _mint(_msgSender(), amount_);
    }

    // Withdraw tokens via swap
    /* function swap(uint pairId, uint256 amount) external returns (bool) {
        DataERC20 storage s = DataERC20Storage.diamondStorage();
        address sender = _msgSender();
        require(s._balances[sender] >= amount, "ERC20: transfer amount exceeds balance");
        _approve(sender, s._swapper, amount);
        bool ok = ITokenSwap(s._swapper).swapTokens(pairId, sender, amount);
        require(ok == true, "SWAP_FAILED");
        return (true);
    } */

    function actionBatch(uint8[] calldata actionList, ActionSwap[] calldata swapList, ActionSubscribe[] calldata subscribeList) external returns (bool) {
        uint8 swapIdx;
        uint8 subscribeIdx;
        uint8 action;
        for (uint8 actionIdx; actionIdx < actionList.length; actionIdx++) {
            action = actionList[actionIdx];
            if (action == uint8(ActionType.SWAP)) {
                _action_swap(swapList[swapIdx]);
                swapIdx++;
            } else if (action == uint8(ActionType.SUBSCRIBE)) {
                _action_subscribe(subscribeList[subscribeIdx]);
                subscribeIdx++;
            }
        }
        return(true);
    }

    function _action_swap(ActionSwap calldata act) internal {
        bool ok = ITokenSwap(act.swapToken).swapTokens(act.swapPairId, _msgSender(), act.swapAmount);
        require(ok == true, "SWAP_FAILED");
    }

    function _action_subscribe(ActionSubscribe calldata act) internal {
        _beginSubscription(act.subscrId, _msgSender(), act.subscrTo, act.subscrTerms, act.pausable, act.subscrSpec);
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

    function beginSubscription(uint128 subscrId, address fromAccount, address toAccount, address terms, bool pausable, SubscriptionSpec calldata spec) external returns (bool) {
        return _beginSubscription(subscrId, fromAccount, toAccount, terms, pausable, spec);
    }

    function _beginSubscription(uint128 subscrId, address fromAccount, address toAccount, address terms, bool pausable, SubscriptionSpec calldata spec) internal returns (bool) {
        DataERC20 storage s = DataERC20Storage.diamondStorage();
        // TODO: verify fromAccount
        require(s._balances[fromAccount] >= 0, "ERC20_BALANCE_REQUIRED");
        require(s._subscriptions[subscrId].mode == 0, "DUPLICATE_SUBSCRIPTION");
        bool ok = ISubscriptionTerms(terms).updateSubscription(subscrId, spec);
        require(ok, "UPDATE_SUBSCRIPTION_FAILED");
        SubscriptionData storage sb = s._subscriptions[subscrId];
        sb.mode = uint8(SubscriptionMode.ACTIVE);
        sb.terms = terms;
        sb.from = fromAccount;
        sb.to = toAccount;
        sb.pausable = pausable;
        emit Subscription(subscrId, fromAccount, toAccount, terms);
        emit SubscriptionUpdate(subscrId, pausable, uint8(EventType.CREATE), spec.maxBudget, spec.timeout, spec.period);
        return (true);
    }

    function processSubscription(SubscriptionEvent calldata subscrData, bool abortOnFail) external returns (bool) {
        return _processSubscription(subscrData, abortOnFail);
    }

    function processSubscriptionBatch(SubscriptionEvent[] calldata subscrList, bool abortOnFail) external returns (bool) {
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
        uint128 subscrId = subscrData.subscrId;
        DataERC20 storage s = DataERC20Storage.diamondStorage();
        SubscriptionData storage sd = s._subscriptions[subscrId];
        // TODO: Validate operator
        if (sd.mode == uint8(SubscriptionMode.NONE)) {
            require(abortOnFail == true, "INVALID_SUBSCRIPTION");
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
        if (sd.mode == uint8(SubscriptionMode.CANCELLED)) {
            require(abortOnFail == true, "CANCELLED_SUBSCRIPTION");
            return(false);
        }
        uint8 res = ISubscriptionTerms(sd.terms).processTerms(subscrData);
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
        _transfer(sender, recipient, amount);

        DataERC20 storage s = DataERC20Storage.diamondStorage();
        uint256 currentAllowance = s._allowances[sender][_msgSender()];

        //require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
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
        DataERC20 storage s = DataERC20Storage.diamondStorage();
        uint256 currentAllowance = s._allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
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
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        //require(recipient != sender, "ERC20: transfer to same address as sender");

        if (recipient == sender) {
            string memory err = string(abi.encodePacked("ERC20_TRANSER_SAME_ADDRESS:", _toString(_msgSender())));
            revert(err);
        }

        _beforeTokenTransfer(sender, recipient, amount);

        DataERC20 storage s = DataERC20Storage.diamondStorage();
        uint256 senderBalance = s._balances[sender];
        uint256 recipBalance = s._balances[recipient];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
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
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

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
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        DataERC20 storage s = DataERC20Storage.diamondStorage();
        uint256 accountBalance = s._balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
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
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        DataERC20 storage s = DataERC20Storage.diamondStorage();
        s._allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
    }
}
