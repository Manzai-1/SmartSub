// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.28;

contract SmartSub {

    address private owner; 
    uint256 private nextId;

    enum subState { 
        Active, 
        Paused 
    }
    

    struct Sub {
        string title;
        uint256 id;
        uint256 durationSeconds;
        uint256 priceWei;
        subState state; 
        address owner; 
        bool exists;
    }


    mapping(uint256 => Sub) public subs;
    mapping(address => mapping(
        uint256 => uint256
    )) public userSubs; //maps address => (subId => exiresAt)


    event subCreated(
        address indexed creator,
        uint256 id
    );


    modifier isSubOwner(uint256 id) {
        require(subs[id].owner == msg.sender, "You must be the owner to do this.");
        _;
    }

    modifier subExists(uint256 id) {
        require(subs[id].exists, "Subscription does not exist.");
        _;
    }

    modifier isSubActive(uint256 id) {
        require(subs[id].state == subState.Active, "Subscription is paused.");
        _;
    }

    modifier meetsPrice(uint256 id) {
        require(msg.value >= subs[id].priceWei, "Transaction value does not meet the price.");
        _;
    }

    constructor () {
        owner  = msg.sender;
        nextId = 1;
    }

    function createSub (
        string memory _title,
        uint256 durationDays,
        uint256 _priceWei,
        bool activate
    ) external {
        uint256 _id = nextId++;

        subs[_id] = Sub({
            title: _title,
            id: _id,
            durationSeconds: durationDays * 1 days,
            priceWei: _priceWei,
            state: activate ? subState.Active : subState.Paused,
            owner: msg.sender,
            exists: true
        });

        emit subCreated(msg.sender, _id);
    }

    function activateSub (uint256 id) external isSubOwner(id) subExists(id) {
        subs[id].state = subState.Active;
    }

    function pauseSub (uint256 id) external isSubOwner(id) subExists(id) {
        subs[id].state = subState.Paused;
    }

    function buySub (uint256 id) external payable subExists(id) isSubActive(id) meetsPrice(id) {
        addTime(msg.sender, id);
    }

    function giftSub (address receiver, uint256 id) external payable subExists(id) isSubActive(id) meetsPrice(id) {
        addTime(receiver, id);
    }

    function addTime (address receiver, uint256 id) internal {
        uint256 addSeconds = subs[id].durationSeconds;
        
        userSubs[receiver][id] > block.timestamp ? 
            userSubs[receiver][id] += addSeconds : 
            userSubs[receiver][id] = (block.timestamp + addSeconds);
    }
}