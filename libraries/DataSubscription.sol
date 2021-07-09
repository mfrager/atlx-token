// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// UTC
struct TimestampData {
    uint64 timestamp;
    bytes4 year;
    bytes5 quarter; // Quarter number in year (1, 2, 3, 4)
    bytes6 month;
    bytes6 week; // Week number in year (01 - 52)
    bytes8 day;
    // bytes19 utc;
}

struct SubscriptionEvent {
    uint128 subscrId;
    uint128 eventId;
    uint8 eventType;
    uint256 amount;
    TimestampData thisBill;
}

struct SubscriptionData {
    uint8 mode;
    address from;
    address to;
    bool pausable;
}

struct SubscriptionSpec {
    uint8 period;
    uint32 timeout;
    uint256 maxBudget;
}

struct ActionSwap {
    address swapToken;
    address fromAccount;
    uint32 swapPairId;
    uint256 swapAmount;
}

struct ActionSubscribe {
    uint128 subscrId;
    address subscrTo;
    bool pausable;
    bool fund;
    uint128 fundId;
    uint256 fundAmount;
    TimestampData fundTimestamp;
    SubscriptionSpec subscrSpec;
}

enum SubscriptionMode { NONE, ACTIVE, CANCELLED, PAUSED }
enum SubscriptionPeriod { INACTIVE, YEARLY, QUARTERLY, MONTHLY, WEEKLY, DAILY }
enum EventType { CREATE, BILL, CANCEL, PAUSE, UNPAUSE, FUND }
enum EventResult { SUCCESS, ABORT, EXCEED_BUDGET, DUPLICATE, TIMEOUT }
enum ActionType { SWAP, SUBSCRIBE }

