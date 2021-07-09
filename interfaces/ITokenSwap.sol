// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITokenSwap {
    event RegisterToken(address indexed token, string label);
    event RegisterSwapPair(uint32 indexed pair, address indexed fromToken, address indexed toToken, uint256 fromRate, uint256 toRate);
    event SwapTokens(address indexed fromAccount, uint32 pair, uint256 fromAmount, uint256 toAmount);

    function setupSwap(address admin) external returns (bool);
    function registerToken(address tokenContract, string memory label) external returns (bool);
    function registerSwapPair(uint32 pairId, address fromToken, address toToken, uint256 fromRate, uint256 toRate) external returns (bool);
    function depositTokens(address fromToken, address fromAccount, uint256 fromAmount) external returns (bool);
    function withdrawTokens(address forToken, address toAccount, uint256 withdrawAmount) external returns (bool);
    function buyTokens(uint32 pairId) external payable returns (bool);
    function swapTokens(uint32 pairId, address fromAccount, uint256 fromAmount) external returns (bool);
}
