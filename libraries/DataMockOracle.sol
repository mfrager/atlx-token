// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct DataMockOracle {
    bool _setupDone;
}

library DataMockOracleStorage {
    bytes32 constant MOCKORACLEV1_POSITION = keccak256("net.atellix.mock_oracle.v1");
    function diamondStorage() internal pure returns (DataMockOracle storage ds) {
        bytes32 position = MOCKORACLEV1_POSITION;
        assembly {
            ds.slot := position
        }
    }
}

