// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITokenSwap {
    event RegisterToken(address indexed token, string label);
    event RegisterSwapPair(uint indexed pair, address indexed fromToken, address indexed toToken, uint fromRate, uint toRate);
    event SwapTokens(address indexed from, address indexed to, uint pair, uint256 fromAmount, uint256 toAmount);

    function registerToken(address _contract, string memory _label) external returns (bool);
    function registerSwapPair(uint pair_, address from_, address to_, uint fromRate_, uint toRate_) external returns (bool);
}
