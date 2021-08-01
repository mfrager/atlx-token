// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/DataSubscription.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Full {
    // Begin AtxV1

    /**
     * @dev Token initialization function
     */
    function setupERC20Token(string memory name, string memory symbol, uint256 amount, uint256 hardcap, address swapper) external;

    // RBAC functions
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;

    function mint(address account, uint256 amount) external returns (bool);
    function burn(address account, uint256 amount) external returns (bool);
    function hardCap() external view returns (uint256);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    function enableMerchant(address merchant) external returns (bool);
    function disableMerchant(address merchant) external returns (bool);
    function isValidMerchant(address merchant) external view returns (bool);

    function enableRevenue(address account) external returns (bool);
    function disableRevenue(address account) external returns (bool);
    function isRevenueAccount(address account) external view returns (bool);
    function signedTransfer(address recipient, uint256 amount, SignedId calldata sid) external returns (bool);
    function signedTransferFrom(address sender, address recipient, uint256 amount, SignedId calldata sid) external returns (bool);

    function grantSubscriptionAdmin(address account, address delegate) external returns (bool);
    function revokeSubscriptionAdmin(address account, address delegate) external returns (bool);
    function beginSubscription(uint128 subscrId, address fromAccount, address toAccount, address terms, bool pausable, SubscriptionSpec calldata spec) external returns (bool);
    function processSubscription(SubscriptionEvent calldata subscrData, bool abortOnFail, SignedId calldata sid) external returns (bool);
    function processSubscriptionBatch(SubscriptionEvent[] calldata subscrList, bool abortOnFail, SignedId calldata sid) external returns (bool);
    function actionBatch(address account, uint8[] calldata actionList, ActionSwap[] calldata swapList, ActionSubscribe[] calldata subscribeList, SignedId calldata sid) external returns (bool);

    /**
     * @dev Emitted when a token has moved after a certain amount of time.
     */
    event BalanceLog(address indexed owner, uint256 balanceNew, uint256 balancePrev, uint256 balancePrevLog, uint ts);
    event DeclareHardCap(uint256 hardcap);
    event EnableMerchantAccount(address indexed merchant);
    event DisableMerchantAccount(address indexed merchant);
    event EnableRevenueAccount(address indexed account);
    event DisableRevenueAccount(address indexed account);
    event Revenue(uint128 indexed eventId, address indexed account, address signer, uint256 indexed amount);
    event Subscription(uint128 indexed subscrId, address indexed from, address indexed to);
    event SubscriptionUpdate(uint128 indexed subscrId, bool pausable, uint8 eventType, uint256 maxBudget, uint32 timeout, uint8 period);
    event SubscriptionBill(uint128 indexed subscrId, uint128 indexed eventId, uint8 eventType, uint256 amount, uint64 timestamp, uint8 errorCode);
    event SubscriptionDelegateGranted(address indexed admin, address delegate);
    event SubscriptionDelegateRevoked(address indexed admin, address delegate);

    // Role-based Access Control

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    // ERC20

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
