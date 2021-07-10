// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct SwapPair {
    address fromToken;
    address toToken;
    uint256 fromRate;
    uint256 toRate;
    bool merchant; // Merchant-only swap
}

struct DataTokenSwap {
    mapping(address => bool) tokenActive;
    mapping(address => uint256) tokenBalances;
    mapping(bytes32 => address) tokenLookup;
    mapping(uint32 => SwapPair) swapPairs;
    bool setupDone;
}

library DataTokenSwapStorage {
    bytes32 constant TokenSwapV1_POSITION = keccak256("net.atellix.token.data.tokenswap.v1");
    function diamondStorage() internal pure returns (DataTokenSwap storage ds) {
        bytes32 position = TokenSwapV1_POSITION;
        assembly {
            ds.slot := position
        }
    }
}

