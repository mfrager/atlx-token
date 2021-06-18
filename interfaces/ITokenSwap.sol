// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITokenSwap {
    event RegisterToken(address indexed token, string label);
    event RegisterSwapPair(uint indexed pair, address indexed fromToken, address indexed toToken, uint fromRate, uint toRate);
    event SwapTokens(address indexed fromAccount, uint pair, uint256 fromAmount, uint256 toAmount);

    function registerToken(address tokenContract, string memory label) external returns (bool);
    function registerSwapPair(uint pairId, address fromToken, address toToken, uint fromRate, uint toRate) external returns (bool);
    function depositTokens(address fromToken, address fromAccount, uint256 fromAmount) external returns (bool);
    function withdrawTokens(address forToken, address toAccount, uint256 withdrawAmount) external returns (bool);
    function swapTokens(uint pairId, address fromAccount, uint256 fromAmount) external returns (bool);
}
