// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// UTC
struct HoldingTimestampData {
    uint64 timestamp;
    bytes4 year;
    bytes5 quarter; // Quarter number in year (1, 2, 3, 4)
    bytes6 month;
    bytes6 week; // Week number in year (01 - 52)
    bytes8 day;
}

struct HoldingEvent {
    uint128 holdingId;
    uint128 eventId;
    uint8 eventType;
    uint256 amount;
    address owner;
    address validator;
    TimestampData tsEvent;
}

struct HoldingData {
    address owner;
    bool allocated;
    bool open;
    HoldingTimestampData tsOpen;
    HoldingTimestampData tsClosed;
}

enum HoldingEvent { CREATE, ALLOCATE, TRANSFER, RETIRE }

// CREATE - Mint to unallocated account
// ALLOCATE - Allocate to initial owners
// TRANSFER - Exchange
// RETIRE - Burn using unallocated account

struct DataSecurityToken {
    mapping(address => mapping(uint128 => uint256) _balances;
    mapping(address => mapping(uint128 => uint32)) _ownerHoldings;
    mapping(address => mapping(uint32 => uint128)) _ownerHoldingIndex;
    mapping(address => bool) _validOwner;
    mapping(uint128 => bool) _validHolding;
    mapping(uint128 => bool) _validSecurity;
    mapping(uint128 => uint256) _totalSupply;
    mapping(uint128 => uint64) _holdingCount;
    mapping(uint128 => HoldingData) _holding;
    address _allocator;
    uint256 _totalHoldingCount;
    string _name;
    string _symbol;
    string _url;
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

