// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.28;

contract SmartSub {

    uint256 private nextId;
    uint256 private totalBalance;
    bool private locked;

    enum subState { 
        Active, 
        Paused 
    }

    struct Sub {
        string title;
        uint256 durationSeconds;
        uint256 priceWei;
        subState state; 
        address owner; 
    }

    mapping(uint256 => Sub) public subs;

    mapping(address => mapping(
        uint256 => uint256
    )) public userSubs;

    mapping(address => uint256) private balance;

    event subCreated(
        address indexed creator,
        uint256 id
    );

    error NotOwner(address caller);
    error FunctionNotFound();
    error PaymentDataMissing();
    error SubscriptionNotFound();
    error SubscriptionPaused();
    error IncorrectValue(uint256 sent, uint256 price);
    error EmptyBalance();


    modifier isSubOwner(uint256 id) {
        if(subs[id].owner != msg.sender) revert NotOwner(msg.sender);
        _;
    }

    modifier subExists(uint256 id) {
        if(subs[id].owner == address(0)) revert SubscriptionNotFound();
        _;
    }

    modifier subIsActive(uint256 id) {
        if(!isSubActive(id)) revert SubscriptionPaused();
        _;
    }

    modifier meetsPrice(uint256 id) {
        if(msg.value != subs[id].priceWei) revert IncorrectValue(
            msg.value, subs[id].priceWei
        );
        _;
    }

    modifier hasBalance() {
        if(balance[msg.sender] == 0) revert EmptyBalance();
        _;
    }

    modifier noReentrancy() {
        require(!locked, "Blocked due to re-entrancy risk.");
        locked = true;
        _;
        locked = false;
    }


    constructor () {
        nextId = 1;
    }

    fallback() external payable {
        revert FunctionNotFound();
    }

    receive() external payable {
        revert PaymentDataMissing();
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
            durationSeconds: durationDays * 1 days,
            priceWei: _priceWei,
            state: activate ? subState.Active : subState.Paused,
            owner: msg.sender
        });

        emit subCreated(msg.sender, _id);
    }

    function activateSub (uint256 id) external subExists(id) isSubOwner(id){
        subs[id].state = subState.Active;
    }

    function pauseSub (uint256 id) external subExists(id) isSubOwner(id){
        subs[id].state = subState.Paused;
    }

    function isSubActive(uint256 id) public view subExists(id) returns(bool) {
        return subs[id].state == subState.Active ? true : false;
    }

    function buySub (uint256 id) 
        external payable subExists(id) subIsActive(id) meetsPrice(id) 
    {
        addTime(msg.sender, id);
        increaseBalance(id);
    }

    function giftSub (address receiver, uint256 id) 
        external payable subExists(id) subIsActive(id) meetsPrice(id) 
    {
        addTime(receiver, id);
        increaseBalance(id);
    }

    function addTime (address receiver, uint256 id) private {
        uint256 expiresAt = userSubs[receiver][id];
        uint256 addSeconds = subs[id].durationSeconds;
        uint256 currentTime = block.timestamp;

        uint256 newExpiration = expiresAt > currentTime ? 
            expiresAt + addSeconds : 
            currentTime + addSeconds;

        userSubs[receiver][id] = newExpiration;
    }

    function increaseBalance (uint256 subId) private {
        balance[subs[subId].owner] += msg.value;
        totalBalance += msg.value;

        assert(totalBalance == address(this).balance);
    }

    function withdrawBalance () external payable hasBalance noReentrancy {
        uint256 amountToTransfer = balance[msg.sender];

        balance[msg.sender] = 0;
        totalBalance -= amountToTransfer;

        payable(msg.sender).transfer(amountToTransfer);
        
        assert(totalBalance == address(this).balance);
    }

    function viewBalance () external view returns (uint256) {
        return balance[msg.sender];
    }
}