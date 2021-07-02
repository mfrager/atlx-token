// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../libraries/DataSubscription.sol";
import "../../utils/Context.sol";

contract SubscriptionTerms is Context {

    mapping(uint128 => mapping(bytes4 => bool)) _yearly;
    mapping(uint128 => mapping(bytes5 => bool)) _quarterly;
    mapping(uint128 => mapping(bytes6 => bool)) _monthly;
    mapping(uint128 => mapping(bytes6 => bool)) _weekly;
    mapping(uint128 => mapping(bytes8 => bool)) _daily;
    mapping(uint128 => SubscriptionSpec) _spec;

    function updateSubscription(uint128 subscrId, SubscriptionSpec calldata inputSpec) external returns (bool) {
        SubscriptionSpec storage sp = _spec[subscrId];
        sp.period = inputSpec.period;
        sp.timeout = inputSpec.timeout;
        sp.maxBudget = inputSpec.maxBudget;
        return(true);
    }

    function processTerms(SubscriptionEvent calldata subscrEvent) external returns (uint8) {
        SubscriptionSpec memory spec = _spec[subscrEvent.subscrId];
        require(spec.period != uint8(SubscriptionPeriod.INACTIVE), "INACTIVE_SUBSCRIPTION");
        if (uint128(block.timestamp) - subscrEvent.thisBill.timestamp >= spec.timeout) {
            return(uint8(EventResult.TIMEOUT));
        }
        if (spec.maxBudget > 0 && subscrEvent.amount > spec.maxBudget) {
            return(uint8(EventResult.EXCEED_BUDGET));
        }
        if (spec.period == uint8(SubscriptionPeriod.YEARLY)) {
            if (_yearly[subscrEvent.subscrId][subscrEvent.thisBill.year]) {
                return(uint8(EventResult.DUPLICATE));
            }
            _yearly[subscrEvent.subscrId][subscrEvent.thisBill.year] = true;
            return(uint8(EventResult.SUCCESS));
        } else if (spec.period == uint8(SubscriptionPeriod.QUARTERLY)) {
            if (_quarterly[subscrEvent.subscrId][subscrEvent.thisBill.quarter]) {
                return(uint8(EventResult.DUPLICATE));
            }
            _quarterly[subscrEvent.subscrId][subscrEvent.thisBill.quarter] = true;
            return(uint8(EventResult.SUCCESS));
        } else if (spec.period == uint8(SubscriptionPeriod.MONTHLY)) {
            if (_monthly[subscrEvent.subscrId][subscrEvent.thisBill.month]) {
                return(uint8(EventResult.DUPLICATE));
            }
            _monthly[subscrEvent.subscrId][subscrEvent.thisBill.month] = true;
            return(uint8(EventResult.SUCCESS));
        } else if (spec.period == uint8(SubscriptionPeriod.WEEKLY)) {
            if (_weekly[subscrEvent.subscrId][subscrEvent.thisBill.week]) {
                return(uint8(EventResult.DUPLICATE));
            }
            _weekly[subscrEvent.subscrId][subscrEvent.thisBill.week] = true;
            return(uint8(EventResult.SUCCESS));
        } else if (spec.period == uint8(SubscriptionPeriod.DAILY)) {
            if (_daily[subscrEvent.subscrId][subscrEvent.thisBill.day]) {
                return(uint8(EventResult.DUPLICATE));
            }
            _daily[subscrEvent.subscrId][subscrEvent.thisBill.day] = true;
            return(uint8(EventResult.SUCCESS));
        }
        return(uint8(EventResult.ABORT));
    }

    // TODO: updateBudget

}
