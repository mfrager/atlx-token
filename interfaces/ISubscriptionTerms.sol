// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/DataSubscription.sol";

interface ISubscriptionTerms {
    function updateSubscription(uint128 subscrId, SubscriptionSpec calldata inputSpec) external returns (bool);
    function processTerms(SubscriptionEvent calldata subscrEvent) external returns (uint8);
}
