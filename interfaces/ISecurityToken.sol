// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct TimestampData {
    uint64 timestamp;
    bytes4 year;
    bytes5 quarter; // Quarter number in year (1, 2, 3, 4)
    bytes6 month;
    bytes6 week; // Week number in year (01 - 52)
    bytes8 day;
}

struct HoldingEvent {
    uint128 securityId;
    uint128 holdingId;
    uint128 eventId;
    uint8 eventType;
    uint256 amount;
    address owner;
    address recipient;
    bool allocated;
    TimestampData eventTs;
}

struct HoldingData {
    uint128 securityId;
    uint128 holdingId;
    uint128 createEventId;
    uint64 holdingIdx;
    uint64 ownerHoldingIdx;
    address owner;
    bool allocated;
    bool retired;
    // bool restricted;
    // TimestampData openTs;
    // TimestampData retiredTs;
    // TimestampData restrictedUntilTs;
}

struct HoldingSummary {
    HoldingData holding;
    uint256 balance;
    bool validOwner;
    bool validHolding;
}

struct Security {
    uint128 securityId;
}

struct SecurityOwner {
    address owner;
}

enum HoldingEventType { CREATE, ALLOCATE, TRANSFER, RETIRE }

/**
 */
interface ISecurityToken {
    function setupSecurityToken() external;
    function grantValidator(address account) external returns (bool);
    function revokeValidator(address account) external returns (bool);
    function enableOwner(uint128 securityId, address owner) external returns (bool);
    function disableOwner(uint128 securityId, address owner) external returns (bool);
    function isValidOwner(uint128 securityId, address owner) external returns (bool);
    function enableSecurity(uint128 securityId) external returns (bool);
    function disableSecurity(uint128 securityId) external returns (bool);
    function enableHolding(uint128 holdingId) external returns (bool);
    function disableHolding(uint128 holdingId) external returns (bool);
    function processHoldingEvent(HoldingEvent calldata h) external returns (bool);
    function listSecurities() external view returns (Security[] memory);
    function listOwners() external view returns (SecurityOwner[] memory);
    function listSecurityHoldings(uint128 securityId) external view returns (HoldingSummary[] memory);
    function listOwnerHoldings(address owner) external view returns (HoldingSummary[] memory);
    function decimals() external view virtual returns (uint8);
    function totalSupply(uint128 securityId) external view returns (uint256);
    function balanceOf(uint128 securityId, address account) external view virtual returns (uint256);

    event Transfer(uint128 indexed securityId, address indexed from, address indexed to, uint256 value);
    event BalanceLog(uint128 indexed securityId, address indexed owner, uint256 balanceNew, uint256 balancePrev, uint ts);
}
