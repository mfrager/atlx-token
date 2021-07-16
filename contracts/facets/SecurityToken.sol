// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../libraries/DataSecurityTokenSecurityToken.sol";
import "../../libraries/DataSecurityToken.sol";
import "../../libraries/AccessControlEnumerable.sol";
import "../../libraries/ReentrancyGuard.sol";
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
contract ERC20Token is Context, ReentrancyGuard, AccessControlEnumerable {

    bytes32 public constant VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");

    /**
     * @dev Emitted when a token has moved after a certain amount of time.
     */
    event BalanceLog(address indexed owner, uint256 balanceNew, uint256 balancePrev, uint ts);

    function setupSecurityToken(string memory name_, string memory symbol_, string memory url_, address manager_, uint256 amount_) external nonReentrant {
        DataSecurityToken storage s = DataSecurityTokenStorage.diamondStorage();
        require(!s._setupDone, "SETUP_ALREADY_DONE");
        s._setupDone = true;
        s._name = name_;
        s._symbol = symbol_;
        s._url = url_;
        address sender = _msgSender();
        _setupRole(DEFAULT_ADMIN_ROLE, sender);
        _setRoleAdmin(VALIDATOR_ROLE, DEFAULT_ADMIN_ROLE);
        _setupRole(VALIDATOR_ROLE, sender);
        if (amount_ > 0) {
            _mint(manager_, amount_);
            // TODO: create holding
        }
    }

    function enableOwner(address owner) external nonReentrant onlyRole(VALIDATOR_ROLE) returns (bool) {
        DataSecurityToken storage s = DataSecurityTokenStorage.diamondStorage();
        s._validOwner[owner] = true;
        // emit EnableOwner(merchant);
        return(true);
    }

    function disableOwner(address owner) external nonReentrant onlyRole(VALIDATOR_ROLE) returns (bool) {
        DataSecurityToken storage s = DataSecurityTokenStorage.diamondStorage();
        s._validOwner[owner] = false;
        // emit DisableOwner(owner);
        return(true);
    }

    function isValidOwner(address owner) external nonReentrant returns (bool) {
        DataSecurityToken storage s = DataSecurityTokenStorage.diamondStorage();
        return(s._validOwner[owner]);
    }

    function grantValidator(address account) external nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        DataSecurityToken storage s = DataSecurityTokenStorage.diamondStorage();
        // emit SubscriptionDelegateGranted(sender, delegate);
        _setupRole(VALIDATOR_ROLE, account);
        return(true);
    }

    function revokeValidator(address account) external nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        address sender = _msgSender();
        DataSecurityToken storage s = DataSecurityTokenStorage.diamondStorage();
        // emit SubscriptionDelegateRevoked(sender, delegate);
        revokeRole(VALIDATOR_ROLE, account);
        return(true);
    }

    function setHolding(uint128 holdingId, HoldingData calldata holdingInfo) {
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

    function mint(address account, uint256 amount) external nonReentrant onlyRole(TOKEN_ADMIN_ROLE) returns (bool) {
        _mint(account, amount);
        return(true);
    }

    function burn(address account, uint256 amount) external nonReentrant onlyRole(TOKEN_ADMIN_ROLE) returns (bool) {
        _burn(account, amount);
        return(true);
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        DataSecurityToken storage s = DataSecurityTokenStorage.diamondStorage();
        return s._name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        DataSecurityToken storage s = DataSecurityTokenStorage.diamondStorage();
        return s._symbol;
    }

    /**
     * @dev Returns the token URL
     */
    function url() public view virtual override returns (string memory) {
        DataSecurityToken storage s = DataSecurityTokenStorage.diamondStorage();
        return s._url;
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
        DataSecurityToken storage s = DataSecurityTokenStorage.diamondStorage();
        return s._totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        DataSecurityToken storage s = DataSecurityTokenStorage.diamondStorage();
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
        DataSecurityToken storage s = DataSecurityTokenStorage.diamondStorage();
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

        DataSecurityToken storage s = DataSecurityTokenStorage.diamondStorage();
        uint256 currentAllowance = s._allowances[sender][_msgSender()];

        if (currentAllowance < amount) {
            string memory err = string(abi.encodePacked("TRANSER_EXCEEDS_ALLOWANCE:", _toString(_msgSender())));
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
        DataSecurityToken storage s = DataSecurityTokenStorage.diamondStorage();
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
        DataSecurityToken storage s = DataSecurityTokenStorage.diamondStorage();
        uint256 currentAllowance = s._allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "DECREASED_ALLOWANCE_BELOW_ZERO");
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
        uint128 security,
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        DataSecurityToken storage s = DataSecurityTokenStorage.diamondStorage();
        require(s._validSecurity[security], "INVALID_SECURITY");
        require(s._validOwner[recipient], "INVALID_OWNER");
        require(sender != address(0), "TRANSFER_FROM_ZERO_ADDRESS");
        require(recipient != address(0), "TRANSFER_TO_ZERO_ADDRESS");
        require(recipient != sender, "TRANSFER_TO_SAME_ADDRESS");

        uint256 senderBalance = s._balances[security][sender];
        uint256 recipBalance = s._balances[security][recipient];
        require(senderBalance >= amount, "TRANSFER_AMOUNT_EXCEEDS_BALANCE");
        unchecked {
            s._balances[security][sender] = senderBalance - amount;
        }
        s._balances[security][recipient] += amount;

        emit Transfer(security, sender, recipient, amount);
        _recordTransfer(security, sender, senderBalance);
        _recordTransfer(security, recipient, recipBalance);
    }

    /** @dev Creates a running total log of holdings
     *
     */
    function _recordTransfer(uint128 security, address owner, uint256 prev) internal virtual {
        DataSecurityToken storage s = DataSecurityTokenStorage.diamondStorage();
        emit BalanceLog(security, owner, s._balances[security][owner], prev, block.timestamp);
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
    function _mint(uint128 security, address account, uint256 amount) internal virtual {
        require(account != address(0), "MINT_TO_ZERO_ADDRESS");
        DataSecurityToken storage s = DataSecurityTokenStorage.diamondStorage();
        uint256 prev = s._balances[security][account];
        s._totalSupply[security] += amount;
        s._balances[security][account] += amount;
        emit Transfer(security, address(0), account, amount);
        emit BalanceLog(account, s._balances[security][account], prev, block.timestamp);
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
        require(account != address(0), "BURN_FROM_ZERO_ADDRESS");
        DataSecurityToken storage s = DataSecurityTokenStorage.diamondStorage();
        uint256 accountBalance = s._balances[account];
        require(accountBalance >= amount, "BURN_AMOUNT_EXCEEDS_BALANCE");
        uint256 prev = s._balances[account];
        unchecked {
            s._balances[account] = accountBalance - amount;
        }
        s._totalSupply -= amount;
        emit Transfer(account, address(0), amount);
        emit BalanceLog(account, s._balances[account], prev, block.timestamp);
    }
}
