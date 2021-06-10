pragma solidity ^0.8.0;

struct DataV1 {
    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;
    mapping(address => uint) _lastTransfer;
    mapping(address => uint256) _lastLogAmount;
    uint256 _totalSupply;
    string _name;
    string _symbol;
    address _minter;
}

library DataV1Storage {
    bytes32 constant DATAV1_POSITION = keccak256("net.atellix.token.data.v1");

    function diamondStorage() internal pure returns (DataV1 storage ds) {
        bytes32 position = DATAV1_POSITION;
        assembly {
            ds.slot := position
        }
    }
}

