// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct SwapPair {
    uint32 pairId;
    address fromToken;
    address toToken;
    uint256 swapRate;
    uint256 baseRate;
    uint256 minimumIn;
    uint256 feeRate;
    address oracleToken;
    uint8 oracleDecimals;
    bool oracleInverse; // Inverse the oracle price
    bool merchant; // Merchant-only swap
    bool mint; // Mint on swap
    bool burn; // Burn on swap
}

interface ITokenSwap {
    event RegisterToken(address indexed token, string label);
    event RegisterSwapPair(uint32 indexed pair, address indexed fromToken, address indexed toToken, uint256 swapRate, uint256 baseRate, uint256 minimumIn, uint256 feeRate, address oracle, bool merchant);
    event SwapTokens(address indexed fromAccount, address indexed toAccount, uint32 pair, uint256 tokensIn, uint256 tokensOut, uint256 feeOut);

    function setupSwap(address admin, address fees) external returns (bool);
    function registerToken(address tokenContract, string memory label) external returns (bool);
    function registerSwapPairs(SwapPair[] calldata pairs) external returns (bool);
    function depositTokens(address fromToken, address fromAccount, uint256 fromAmount) external returns (bool);
    function withdrawTokens(address forToken, address toAccount, uint256 withdrawAmount) external returns (bool);
    function swapTokens(uint32 pairId, address fromAccount, address payable toAccount, uint256 tokensIn) external returns (bool);
}
