// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../libraries/DataTokenSwap.sol";
// import "../../interfaces/IERC20.sol";
import "../../utils/Context.sol";

contract TokenSwap is Context {

    event RegisterToken(address indexed token, string label);
    event RegisterSwapPair(uint indexed pair, address indexed fromToken, address indexed toToken, uint fromRate, uint toRate);
    event SwapTokens(address indexed from, address indexed to, uint pair, uint256 fromAmount, uint256 toAmount);

    function registerToken(address _contract, string memory _label) external returns (bool) {
        DataTokenSwap storage s = DataTokenSwapStorage.diamondStorage();
        bytes32 lookupHash = keccak256(abi.encode(_label));
        require(s.tokenLookup[lookupHash] == address(0), "DUPLICATE_TOKEN");
        s.tokenLookup[lookupHash] = _contract;
        s.tokenActive[_contract] = true;
        emit RegisterToken(_contract, _label);
        return (true);
    }

    function registerSwapPair(uint pair_, address from_, address to_, uint fromRate_, uint toRate_) external returns (bool) {
        DataTokenSwap storage s = DataTokenSwapStorage.diamondStorage();
        SwapPair storage sp = s.swapPairs[pair_];
        require(sp.fromToken == address(0), "DUPLICATE_SWAP_PAIR");
        require(to_ != from_, "INVALID_SWAP_SAME_TOKEN");
        require(s.tokenActive[from_] == true, "INVALID_FROM_TOKEN");
        require(s.tokenActive[to_] == true, "INVALID_TO_TOKEN");
        sp.fromToken = from_;
        sp.toToken = to_;
        sp.fromRate = fromRate_;
        sp.toRate = toRate_;
        emit RegisterSwapPair(pair_, from_, to_, fromRate_, toRate_);
        return (true);
    }
}
