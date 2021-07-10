// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DataSubscription.sol";

struct DataERC20 {
    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;
    mapping(address => uint) _lastTransfer;
    mapping(address => uint256) _lastLogAmount;
    mapping(address => bool) _validMerchant;
    mapping(address => bool) _subscriptionAdmin;
    mapping(address => mapping(address => bool)) _subscriptionDelegate;
    mapping(uint128 => SubscriptionData) _subscriptions;
    mapping(uint128 => SubscriptionSpec) _subscriptionSpec;
    mapping(uint128 => mapping(bytes4 => bool)) _yearly;
    mapping(uint128 => mapping(bytes5 => bool)) _quarterly;
    mapping(uint128 => mapping(bytes6 => bool)) _monthly;
    mapping(uint128 => mapping(bytes6 => bool)) _weekly;
    mapping(uint128 => mapping(bytes8 => bool)) _daily;
    uint256 _subscriptionCounter;
    uint256 _totalSupply;
    string _name;
    string _symbol;
    address _swapper;
    bool _setupDone;
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

