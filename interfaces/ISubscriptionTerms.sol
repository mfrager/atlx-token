// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/DataSubscription.sol";

interface ISubscriptionTerms {
    event SubscriptionLog(uint indexed eventId, uint8 eventType, uint256 amount, uint64 timestamp, uint8 errorCode);

    function processTerms(SubscriptionEvent calldata subscrEvent) external returns (uint8);
}
