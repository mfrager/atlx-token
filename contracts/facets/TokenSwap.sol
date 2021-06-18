// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../libraries/DataTokenSwap.sol";
import "../../interfaces/IERC20.sol";
import "../../utils/Context.sol";

contract TokenSwap is Context {

    event RegisterToken(address indexed token, string label);
    event RegisterSwapPair(uint indexed pair, address indexed fromToken, address indexed toToken, uint fromRate, uint toRate);
    event SwapTokens(address indexed fromAccount, uint pair, uint256 fromAmount, uint256 toAmount);

    function registerToken(address tokenContract, string memory label) external returns (bool) {
        DataTokenSwap storage s = DataTokenSwapStorage.diamondStorage();
        bytes32 lookupHash = keccak256(abi.encode(label));
        require(s.tokenLookup[lookupHash] == address(0), "DUPLICATE_TOKEN");
        s.tokenLookup[lookupHash] = tokenContract;
        s.tokenActive[tokenContract] = true;
        emit RegisterToken(tokenContract, label);
        return (true);
    }

    function registerSwapPair(uint pairId, address fromToken, address toToken, uint fromRate, uint toRate) external returns (bool) {
        DataTokenSwap storage s = DataTokenSwapStorage.diamondStorage();
        SwapPair storage sp = s.swapPairs[pairId];
        require(sp.fromToken == address(0), "DUPLICATE_SWAP_PAIR");
        require(toToken != fromToken, "INVALID_SWAP_SAME_TOKEN");
        require(s.tokenActive[fromToken] == true, "INVALID_FROM_TOKEN");
        require(s.tokenActive[toToken] == true, "INVALID_TO_TOKEN");
        // Main pair
        sp.fromToken = fromToken;
        sp.toToken = toToken;
        sp.fromRate = fromRate;
        sp.toRate = toRate;
        emit RegisterSwapPair(pairId, fromToken, toToken, fromRate, toRate);
        // Alternate pair
        pairId = pairId + 1;
        SwapPair storage sp2 = s.swapPairs[pairId];
        sp2.fromToken = toToken;
        sp2.toToken = fromToken;
        sp2.fromRate = toRate;
        sp2.toRate = fromRate;
        emit RegisterSwapPair(pairId, toToken, fromToken, toRate, fromRate);
        return (true);
    }

    function depositTokens(address fromToken, address fromAccount, uint256 fromAmount) external returns (bool) {
        DataTokenSwap storage s = DataTokenSwapStorage.diamondStorage();
        require(s.tokenActive[fromToken] == true, "INVALID_FROM_TOKEN");
        bool ok = IERC20(fromToken).transferFrom(fromAccount, address(this), fromAmount);
        require(ok == true, "ERC20_TRANSER_FAILED");
        s.tokenBalances[fromToken] = s.tokenBalances[fromToken] + fromAmount;
        return (true);
    }

    function withdrawTokens(address forToken, address toAccount, uint256 fromAmount) external returns (bool) {
        return (true);
    }

    function swapTokens(uint pairId, uint256 fromAmount) external returns (bool) {
        address fromAccount = _msgSender();
        DataTokenSwap storage s = DataTokenSwapStorage.diamondStorage();
        SwapPair storage sp = s.swapPairs[pairId];
        require(sp.fromToken != address(0), "INVALID_SWAP_PAIR");
        require(sp.fromRate == 1 && sp.toRate == 1, "NO_FANCY_SWAPS");
        require(s.tokenBalances[sp.toToken] >= fromAmount, "NOT_ENOUGH_TOKENS_TO_SWAP");
        bool ok;
        ok = IERC20(sp.fromToken).transferFrom(fromAccount, address(this), fromAmount);
        require(ok == true, "ERC20_TRANSER_IN_FAILED");
        s.tokenBalances[sp.fromToken] = s.tokenBalances[sp.fromToken] + fromAmount;

        s.tokenBalances[sp.toToken] = s.tokenBalances[sp.toToken] - fromAmount;
        ok = IERC20(sp.toToken).transfer(fromAccount, fromAmount);
        require(ok == true, "ERC20_TRANSER_OUT_FAILED");

        emit SwapTokens(fromAccount, pairId, fromAmount, fromAmount);
    }
}
