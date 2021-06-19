// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Always UTC
struct TimestampData {
    uint64 timestamp;
    bytes4 year;
    bytes6 month;
    bytes8 day;
    bytes6 week; // Week number in year
}

struct SubscriptionEvent {
    uint128 subscrId;
    uint128 eventId;
    uint8 eventType;
    uint256 amount;
    // TimestampData current;
    // TimestampData nextRebill;
}

enum SubscriptionMode { NONE, ACTIVE, CANCELLED, PAUSED }
enum SubscriptionPeriod { YEARLY, MONTHLY, WEEKLY, DAILY }
enum EventType { NULL, REBILL, CANCEL, PAUSE, UNPAUSE }
enum EventResult { SUCCESS, ABORT, EXCEED_BUDGET, DUPLICATE_PERIOD }

