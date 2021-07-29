// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITokenSwap {
    event RegisterToken(address indexed token, string label);
    event RegisterSwapPair(uint32 indexed pair, address indexed fromToken, address indexed toToken);
    event SwapTokens(address indexed fromAccount, address indexed toAccount, uint32 pair, uint256 tokensIn, uint256 tokensOut);

    function setupSwap(address admin) external returns (bool);
    function registerToken(address tokenContract, string memory label) external returns (bool);
    function registerSwapPair(SwapPair[] calldata pairs) external returns (bool);
    function depositTokens(address fromToken, address fromAccount, uint256 fromAmount) external returns (bool);
    function withdrawTokens(address forToken, address toAccount, uint256 withdrawAmount) external returns (bool);
    function swapTokens(uint32 pairId, address fromAccount, address payable toAccount, uint256 tokensIn) external returns (bool);
}
