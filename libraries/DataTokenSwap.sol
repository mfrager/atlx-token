// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct SwapPair {
    uint32 pairId;
    address fromToken;
    address toToken;
    uint256 fromRate;
    uint256 toRate;
    address oracleToken;
    uint8 oracleDecimals;
    bool merchant; // Merchant-only swap
    bool mint; // Mint on swap
    bool burn; // Burn on swap
}

struct DataTokenSwap {
    mapping(address => bool) tokenActive;
    mapping(address => uint256) tokenBalances;
    mapping(bytes32 => address) tokenLookup;
    mapping(uint32 => SwapPair) swapPairs;
    bool setupDone;
}

library DataTokenSwapStorage {
    bytes32 constant TokenSwapV1_POSITION = keccak256("net.atellix.token_swap.v1");
    function diamondStorage() internal pure returns (DataTokenSwap storage ds) {
        bytes32 position = TokenSwapV1_POSITION;
        assembly {
            ds.slot := position
        }
    }
}

