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
        uint256 durationDays;
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


    constructor () {
        owner  = msg.sender;
        nextId = 1;
    }

    function createSub (
        string memory _title,
        uint256 _durationDays,
        uint256 _priceWei,
        bool activate
    ) public {
        uint256 _id = nextId++;

        subs[_id] = Sub({
            title: _title,
            id: _id,
            durationDays: _durationDays,
            priceWei: _priceWei,
            state: activate ? subState.Active : subState.Paused,
            owner: msg.sender,
            exists: true
        });

        emit subCreated(msg.sender, _id);
    }

    function activateSub (uint256 id) public isSubOwner(id) subExists(id) {
        
    }
}