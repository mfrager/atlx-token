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

struct HoldingEvent {
    uint128 securityId;
    uint128 holdingId;
    uint128 eventId;
    uint8 eventType;
    uint256 amount;
    address owner;
    address recipient;
    TimestampData eventTs;
}

struct HoldingData {
    uint128 securityId;
    uint128 holdingId;
    address owner;
    uint32 securityIdx;
    uint32 ownerIdx;
    uint32 holdingIdx;
    bool allocated;
    bool retired;
    // bool restricted;
    // TimestampData openTs;
    // TimestampData retiredTs;
    // TimestampData restrictedUntilTs;
}

struct Security {
    uint128 securityId;
}

struct SecurityOwner {
    address owner;
}

enum HoldingEvent { CREATE, ALLOCATE, TRANSFER, RETIRE }

// CREATE - Mint to unallocated account
// ALLOCATE - Allocate to initial owners
// TRANSFER - Exchange
// RETIRE - Burn using unallocated account

struct DataSecurityToken {
    mapping(address => mapping(uint128 => uint256)) _balances;
    mapping(address => mapping(uint32 => uint128)) _ownerHoldingIndex;
    mapping(uint128 => mapping(address => bool)) _securityHolding;
    mapping(uint128 => mapping(address => bool)) _validOwner;
    mapping(uint128 => bool) _validSecurity;
    mapping(uint128 => bool) _validHolding;
    mapping(uint128 => HoldingData) _holding;
    mapping(uint128 => uint256) _totalSupply;
    mapping(address => uint32) _ownerHoldingCount;
    mapping(uint128 => uint32) _securityHoldingCount;
    mapping(uint32 => uint128) _securityIndex;
    mapping(uint32 => address) _ownerIndex;
    mapping(uint32 => uint128) _holdingIndex;
    address _allocator;
    uint32 _totalSecurityCount;
    uint32 _totalOwnerCount;
    uint64 _totalHoldingCount;
    bool _setupDone;
}

library DataSecurityTokenStorage {
    bytes32 constant SECTOKENV1_POSITION = keccak256("net.atellix.token.data.security.v1");
    function diamondStorage() internal pure returns (DataSecurityToken storage ds) {
        bytes32 position = SECTOKENV1_POSITION;
        assembly {
            ds.slot := position
        }
    }
}

