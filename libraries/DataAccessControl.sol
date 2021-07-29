// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utils/structs/EnumerableSet.sol";

struct RoleData {
    mapping(address => bool) members;
    bytes32 adminRole;
}

// using EnumerableSet for EnumerableSet.AddressSet;

struct DataAccessControl {
    // address _owner; // for Ownable
    mapping(bytes32 => RoleData) _roles;
    mapping(bytes32 => EnumerableSet.AddressSet) _roleMembers;
    EnumerableSet.AddressSet _banList;
}

library DataAccessControlStorage {
    bytes32 constant ACCESSV1_POSITION = keccak256("net.atellix.access.v1");
    function diamondStorage() internal pure returns (DataAccessControl storage ds) {
        bytes32 position = ACCESSV1_POSITION;
        assembly {
            ds.slot := position
        }
    }
}

