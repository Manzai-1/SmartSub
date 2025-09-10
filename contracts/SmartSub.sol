// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.28;

contract SmartSub {

    enum subState { 
        active, 
        paused 
    }

    struct Subscription {
        string title;
        uint256 id;
        uint256 durationDays;
        uint256 priceWei;
        subState state; 
        address owner; 
        bool exists;
    }

    struct userSubscription {
        uint256 subId;
        uint256 durationDays;
    }

    mapping(uint256 => Subscription) public subscriptions;
    mapping(address => mapping(
        uint256 => userSubscription
    )) public userSubscriptions;

}