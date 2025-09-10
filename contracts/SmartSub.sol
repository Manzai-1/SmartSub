// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.28;

contract SmartSub {

    address private owner; 
    uint256 private nextId;

    enum subState { 
        Active, 
        Paused 
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

    event subscriptionCreated(
        address indexed creator,
        uint256 id
    );

    constructor () {
        owner  = msg.sender;
    }

    function createSubscription (
        string memory _title,
        uint256 _durationDays,
        uint256 _priceWei,
        bool activate
    ) public {
        uint256 _id = nextId++;

        subscriptions[_id] = Subscription({
            title: _title,
            id: _id,
            durationDays: _durationDays,
            priceWei: _priceWei,
            state: activate ? subState.Active : subState.Paused,
            owner: msg.sender,
            exists: true
        });

        emit subscriptionCreated(msg.sender, _id);
    }
}