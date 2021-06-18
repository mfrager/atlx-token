// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct DataERC20 {
    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;
    mapping(address => uint) _lastTransfer;
    mapping(address => uint256) _lastLogAmount;
    uint256 _totalSupply;
    string _name;
    string _symbol;
    address _minter;
}

library DataERC20Storage {
    bytes32 constant ERC20V1_POSITION = keccak256("net.atellix.token.data.erc20.v1");
    function diamondStorage() internal pure returns (DataERC20 storage ds) {
        bytes32 position = ERC20V1_POSITION;
        assembly {
            ds.slot := position
        }
    }
}

