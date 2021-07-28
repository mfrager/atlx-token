// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// UTC
struct TimestampData {
    uint64 timestamp;
    bytes4 year;
    bytes5 quarter; // Quarter number in year (1, 2, 3, 4)
    bytes6 month;
    bytes6 week; // Week number in year (01 - 52)
    bytes8 day;
}

struct TransferData {
    address recipient;
    uint256 amount;
    uint256 payment;
    address paymentToken;
}

struct HoldingEvent {
    uint128 securityId;
    uint128 holdingId;
    uint128 eventId;
    uint8 eventType;
    address owner;
    bool allocated;
    TransferData transfer;
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

struct SecurityData {
    uint128 securityId;
    uint64 securityIdx;
    uint64 securityHoldingCount;
    address admin;
    bool hasExternalToken;
    address externalToken;
}

struct OwnerData {
    address owner;
    uint64 ownerIdx;
    uint64 ownerHoldingCount;
}

struct Security {
    uint128 securityId;
}

struct SecurityOwner {
    address owner;
}

enum HoldingEventType { CREATE, ALLOCATE, TRANSFER, RETIRE }

// CREATE - Mint to unallocated account
// ALLOCATE - Allocate to initial owners
// TRANSFER - Exchange
// RETIRE - Burn using unallocated account

struct DataSecurityToken {
    mapping(address => OwnerData) _owner;
    mapping(uint128 => SecurityData) _security;
    mapping(uint128 => HoldingData) _holding;
    mapping(address => mapping(uint64 => uint128)) _ownerHoldingIndex;
    mapping(uint128 => mapping(uint64 => uint128)) _securityHoldingIndex;
    mapping(uint128 => mapping(address => bool)) _securityHolding;
    mapping(uint128 => mapping(address => uint256)) _balances;
    mapping(uint128 => mapping(address => bool)) _validOwner;
    mapping(uint128 => bool) _validSecurity;
    mapping(uint128 => bool) _validHolding;
    mapping(uint128 => uint256) _totalSupply;
    mapping(uint64 => uint128) _securityIndex;
    mapping(uint64 => address) _ownerIndex;
    mapping(uint64 => uint128) _holdingIndex;
    uint64 _totalSecurityCount;
    uint64 _totalOwnerCount;
    uint64 _totalHoldingCount;
    bool _setupDone;
}

library DataSecurityTokenStorage {
    bytes32 constant SECTOKENV1_POSITION = keccak256("net.atellix.security_token.v1");
    function diamondStorage() internal pure returns (DataSecurityToken storage ds) {
        bytes32 position = SECTOKENV1_POSITION;
        assembly {
            ds.slot := position
        }
    }
}

