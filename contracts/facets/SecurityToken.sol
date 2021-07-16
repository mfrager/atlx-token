// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../libraries/DataSecurityToken.sol";
import "../../libraries/AccessControlEnumerable.sol";
import "../../libraries/ReentrancyGuard.sol";
import "../../utils/Context.sol";

/**
 * Security token from Atellix
 */
contract SecurityToken is Context, ReentrancyGuard, AccessControlEnumerable {

    bytes32 public constant VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");

    /**
     * @dev Emitted when a token has moved.
     */
    event Transfer(uint128 indexed securityId, address indexed from, address indexed to, uint256 value);
    event BalanceLog(uint128 indexed securityId, address indexed owner, uint256 balanceNew, uint256 balancePrev, uint ts);

    function setupSecurityToken() external nonReentrant {
        DataSecurityToken storage s = DataSecurityTokenStorage.diamondStorage();
        require(!s._setupDone, "SETUP_ALREADY_DONE");
        s._setupDone = true;
        address sender = _msgSender();
        _setupRole(DEFAULT_ADMIN_ROLE, sender);
        _setRoleAdmin(VALIDATOR_ROLE, DEFAULT_ADMIN_ROLE);
        _setupRole(VALIDATOR_ROLE, sender);
    }

    function enableOwner(uint128 securityId, address owner) external nonReentrant onlyRole(VALIDATOR_ROLE) returns (bool) {
        DataSecurityToken storage s = DataSecurityTokenStorage.diamondStorage();
        s._validOwner[securityId][owner] = true;
        // emit EnableOwner(merchant);
        return(true);
    }

    function disableOwner(uint128 securityId, address owner) external nonReentrant onlyRole(VALIDATOR_ROLE) returns (bool) {
        DataSecurityToken storage s = DataSecurityTokenStorage.diamondStorage();
        s._validOwner[securityId][owner] = false;
        // emit DisableOwner(owner);
        return(true);
    }

    function isValidOwner(uint128 securityId, address owner) external nonReentrant returns (bool) {
        DataSecurityToken storage s = DataSecurityTokenStorage.diamondStorage();
        return(s._validOwner[securityId][owner]);
    }

    function grantValidator(address account) external nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        DataSecurityToken storage s = DataSecurityTokenStorage.diamondStorage();
        // emit ValdiatorGranted(sender, delegate);
        _setupRole(VALIDATOR_ROLE, account);
        return(true);
    }

    function revokeValidator(address account) external nonReentrant onlyRole(DEFAULT_ADMIN_ROLE) returns (bool) {
        DataSecurityToken storage s = DataSecurityTokenStorage.diamondStorage();
        // emit ValidatorRevoked(sender, delegate);
        revokeRole(VALIDATOR_ROLE, account);
        return(true);
    }

    function enableSecurity(uint128 securityId) external nonReentrant onlyRole(VALIDATOR_ROLE) returns (bool) {
        DataSecurityToken storage s = DataSecurityTokenStorage.diamondStorage();
        s._validSecurity[securityId] = true;
        // emit SecurityEnabled(securityId);
        return(true);
    }

    function disableSecurity(uint128 securityId) external nonReentrant onlyRole(VALIDATOR_ROLE) returns (bool) {
        DataSecurityToken storage s = DataSecurityTokenStorage.diamondStorage();
        s._validSecurity[securityId] = false;
        // emit SecurityDisabled(securityId);
        return(true);
    }

    function enableHolding(uint128 holdingId) external nonReentrant onlyRole(VALIDATOR_ROLE) returns (bool) {
        DataSecurityToken storage s = DataSecurityTokenStorage.diamondStorage();
        s._validHolding[holdingId] = true;
        // emit HoldingEnabled(holdingId);
        return(true);
    }

    function disableHolding(uint128 holdingId) external nonReentrant onlyRole(VALIDATOR_ROLE) returns (bool) {
        DataSecurityToken storage s = DataSecurityTokenStorage.diamondStorage();
        s._validHolding[holdingId] = false;
        // emit HoldingDisabled(holdingId);
        return(true);
    }

    function processHoldingEvent(HoldingEvent calldata h) external nonReentrant returns (bool) {
        address sender = _msgSender();
        DataSecurityToken storage s = DataSecurityTokenStorage.diamondStorage();
        if (h.eventType == uint8(HoldingEventType.CREATE)) {
            // Create new holding
            require(hasRole(VALIDATOR_ROLE, sender), "ACCESS_DENIED");
            require(h.recipient == address(0), "INVALID_RECIPIENT");
            require(!s._validSecurity[h.holdingId], "HOLDING_MATCHES_EXISTING_SECURITY");
            require(!s._validHolding[h.securityId], "SECURITY_MATCHES_EXISTING_HOLDING");
            s._validSecurity[h.securityId] = true;
            s._validOwner[h.securityId][h.owner] = true;
            s._validHolding[h.holdingId] = true;
            _createSecurity(h.securityId, h.owner);
            _createOwner(h.owner);
            _createHolding(h);
            _mint(h.securityId, h.owner, h.amount);
        } else if (h.eventType == uint8(HoldingEventType.ALLOCATE)) {
            // Create allocate holding by transferring to new owner
            require(s._validHolding[h.holdingId], "INVALID_HOLDING");
            require(s._validOwner[h.securityId][h.owner], "INVALID_OWNER");
            require(hasRole(VALIDATOR_ROLE, sender), "ACCESS_DENIED");
            HoldingData storage hd = s._holding[h.holdingId];
            hd.allocated = h.allocated;
        } else if (h.eventType == uint8(HoldingEventType.TRANSFER)) {
            // Create transfer an allocated holding
            require(s._validHolding[h.holdingId], "INVALID_HOLDING");
            require(s._validOwner[h.securityId][h.owner], "INVALID_OWNER");
            bool allowed = false;
            if (hasRole(VALIDATOR_ROLE, sender)) {
                allowed = true;
            } else if (s._holding[h.holdingId].owner == sender) {
                allowed = true;
            }
            require(allowed, "ACCESS_DENIED");
            // TODO: Check for transfer restrictions
        } else if (h.eventType == uint8(HoldingEventType.RETIRE)) {
            // Retire a holding and burn any remaining tokens
            require(hasRole(VALIDATOR_ROLE, sender), "ACCESS_DENIED");
        }
    }

    function _createSecurity(uint128 securityId, address admin) internal {
        DataSecurityToken storage s = DataSecurityTokenStorage.diamondStorage();
        SecurityData storage sd = s._security[securityId];
        if (sd.securityHoldingCount == 0) {
            // Need to create since there will always be at least one holding
            sd.securityId = securityId;
            sd.securityIdx = s._totalSecurityCount;
            sd.admin = admin;
            s._securityIndex[s._totalSecurityCount] = securityId;
            s._totalSecurityCount++;
        }
    }

    function _createOwner(address owner) internal {
        DataSecurityToken storage s = DataSecurityTokenStorage.diamondStorage();
        OwnerData storage od = s._owner[owner];
        if (od.ownerHoldingCount == 0) {
            od.owner = owner;
            od.ownerIdx = s._totalOwnerCount;
            s._ownerIndex[s._totalOwnerCount] = owner;
            s._totalOwnerCount++;
        }
    }

    function _createHolding(HoldingEvent memory h) internal {
        DataSecurityToken storage s = DataSecurityTokenStorage.diamondStorage();
        if (!s._securityHolding[h.securityId][h.owner]) {
            SecurityData storage sd = s._security[h.securityId];
            s._securityHolding[h.securityId][h.owner] = true;
            s._securityHoldingIndex[h.securityId][sd.securityHoldingCount] = h.holdingId;
            s._holdingIndex[s._totalHoldingCount] = h.holdingId;
            OwnerData storage od = s._owner[h.owner];
            s._ownerHoldingIndex[h.owner][od.ownerHoldingCount] = h.holdingId;
            HoldingData storage hd = s._holding[h.holdingId];
            hd.securityId = h.securityId;
            hd.holdingId = h.holdingId;
            hd.createEventId = h.eventId;
            hd.holdingIdx = s._totalHoldingCount;
            hd.ownerHoldingIdx = od.ownerHoldingCount;
            hd.owner = h.owner;
            hd.allocated = h.allocated;
            hd.retired = false;
            od.ownerHoldingCount++;
            sd.securityHoldingCount++;
            s._totalHoldingCount++;
        }
    }

    function listSecurities() external view returns (Security[] memory) {
        DataSecurityToken storage s = DataSecurityTokenStorage.diamondStorage();
        Security[] memory list = new Security[](s._totalSecurityCount);
        for (uint64 i = 0; i < s._totalSecurityCount; i++) {
            list[i].securityId = s._securityIndex[i];
        }
        return(list);
    }

    function listOwners() external view returns (SecurityOwner[] memory) {
        DataSecurityToken storage s = DataSecurityTokenStorage.diamondStorage();
        SecurityOwner[] memory list = new SecurityOwner[](s._totalOwnerCount);
        for (uint64 i = 0; i < s._totalOwnerCount; i++) {
            list[i].owner = s._ownerIndex[i];
        }
        return(list);
    }

    function listSecurityHoldings(uint128 securityId) external view returns (HoldingSummary[] memory) {
        DataSecurityToken storage s = DataSecurityTokenStorage.diamondStorage();
        SecurityData storage sd = s._security[securityId];
        HoldingSummary[] memory list = new HoldingSummary[](sd.securityHoldingCount);
        for (uint64 i = 0; i < sd.securityHoldingCount; i++) {
            uint128 holdingId = s._securityHoldingIndex[securityId][i];
            HoldingData storage hd = s._holding[holdingId];
            HoldingSummary memory hs;
            hs.holding = hd;
            hs.balance = s._balances[securityId][hd.owner];
            hs.validOwner = s._validOwner[hd.securityId][hd.owner];
            hs.validHolding = s._validHolding[hd.holdingId];
            list[i] = hs;
        }
        return(list);
    }

    function listOwnerHoldings(address owner) external view returns (HoldingSummary[] memory) {
        DataSecurityToken storage s = DataSecurityTokenStorage.diamondStorage();
        OwnerData storage sd = s._owner[owner];
        HoldingSummary[] memory list = new HoldingSummary[](sd.ownerHoldingCount);
        for (uint64 i = 0; i < sd.ownerHoldingCount; i++) {
            uint128 holdingId = s._ownerHoldingIndex[owner][i];
            HoldingData storage hd = s._holding[holdingId];
            HoldingSummary memory hs;
            hs.holding = hd;
            hs.balance = s._balances[hd.securityId][hd.owner];
            hs.validOwner = s._validOwner[hd.securityId][hd.owner];
            hs.validHolding = s._validHolding[hd.holdingId];
            list[i] = hs;
        }
        return(list);
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
     */
    function decimals() external view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev The number of tokens for each security times 10**18
     */
    function totalSupply(uint128 securityId) external view virtual returns (uint256) {
        DataSecurityToken storage s = DataSecurityTokenStorage.diamondStorage();
        return s._totalSupply[securityId];
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(uint128 securityId, address account) external view virtual returns (uint256) {
        DataSecurityToken storage s = DataSecurityTokenStorage.diamondStorage();
        return s._balances[securityId][account];
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
    function _transfer(uint128 securityId, address sender, address recipient, uint256 amount) internal virtual {
        DataSecurityToken storage s = DataSecurityTokenStorage.diamondStorage();
        require(s._validSecurity[securityId], "INVALID_SECURITY");
        require(s._validOwner[securityId][recipient], "INVALID_OWNER");
        require(sender != address(0), "TRANSFER_FROM_ZERO_ADDRESS");
        require(recipient != address(0), "TRANSFER_TO_ZERO_ADDRESS");
        require(recipient != sender, "TRANSFER_TO_SAME_ADDRESS");

        uint256 senderBalance = s._balances[securityId][sender];
        uint256 recipBalance = s._balances[securityId][recipient];
        require(senderBalance >= amount, "TRANSFER_AMOUNT_EXCEEDS_BALANCE");
        unchecked {
            s._balances[securityId][sender] = senderBalance - amount;
        }
        s._balances[securityId][recipient] += amount;

        emit Transfer(securityId, sender, recipient, amount);
        _recordTransfer(securityId, sender, senderBalance);
        _recordTransfer(securityId, recipient, recipBalance);
    }

    /** 
     * @dev Creates a running total log of holdings
     */
    function _recordTransfer(uint128 securityId, address owner, uint256 prev) internal virtual {
        DataSecurityToken storage s = DataSecurityTokenStorage.diamondStorage();
        emit BalanceLog(securityId, owner, s._balances[securityId][owner], prev, block.timestamp);
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
    function _mint(uint128 securityId, address account, uint256 amount) internal virtual {
        require(account != address(0), "MINT_TO_ZERO_ADDRESS");
        DataSecurityToken storage s = DataSecurityTokenStorage.diamondStorage();
        uint256 prev = s._balances[securityId][account];
        s._totalSupply[securityId] += amount;
        s._balances[securityId][account] += amount;
        emit Transfer(securityId, address(0), account, amount);
        emit BalanceLog(securityId, account, s._balances[securityId][account], prev, block.timestamp);
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
    function _burn(uint128 securityId, address account, uint256 amount) internal virtual {
        require(account != address(0), "BURN_FROM_ZERO_ADDRESS");
        DataSecurityToken storage s = DataSecurityTokenStorage.diamondStorage();
        uint256 accountBalance = s._balances[securityId][account];
        require(accountBalance >= amount, "BURN_AMOUNT_EXCEEDS_BALANCE");
        uint256 prev = s._balances[securityId][account];
        unchecked {
            s._balances[securityId][account] = accountBalance - amount;
        }
        s._totalSupply[securityId] -= amount;
        emit Transfer(securityId, account, address(0), amount);
        emit BalanceLog(securityId, account, s._balances[securityId][account], prev, block.timestamp);
    }
}
