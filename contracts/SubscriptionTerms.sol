// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../libraries/DataSubscription.sol";
import "../../utils/Context.sol";

contract SubscriptionTerms is Context {

    event SubscriptionLog(uint indexed eventId, uint128 indexed subscrId, address indexed subscriber, uint8 eventType, uint256 amount, uint64 timestamp, uint8 errorCode);

    uint256 _maxBudget;
    uint32 _timeout;
    uint8 _period;

    mapping(uint128 => mapping(bytes4 => bool)) _yearly;
    mapping(uint128 => mapping(bytes6 => bool)) _monthly;
    // mapping(bytes6 => bool) _monthly;

    constructor(uint256 maxBudget, uint32 timeout, uint8 period) {
        _maxBudget = maxBudget;
        _timeout = timeout;
        _period = period;
    }

    function processTerms(SubscriptionEvent calldata subscrEvent) external returns (uint8) {
        return(uint8(EventResult.SUCCESS));
    }

    // TODO: updateBudget

}
