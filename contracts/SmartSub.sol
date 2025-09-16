// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.28;

contract SmartSub {

    uint256 private nextId;
    uint256 private contractBalance;
    bool private locked;

    enum SubState {Active, Paused}

    struct Sub {
        uint256 durationSeconds;
        uint256 priceWei;
        SubState state; 
        address owner; 
    }

    struct User {
        uint256[] subIds;
        mapping(uint256 => uint256) subExpirations;
    }

    mapping(uint256 => Sub) public subs;
    mapping(address => User) private users;
    mapping(address => uint256) private balances;

    event SubCreated(
        string indexed title,
        address indexed creator,
        uint256 id
    );
    event SubPaused(uint256 indexed id);
    event SubActivated(uint256 indexed id);
    event SubPriceUpdated(uint256 id, uint256 priceWei);
    event SubDurationUpdated(uint256 id, uint256 durationSeconds);
    event timeAddedToSub(
        address indexed receiver,
        uint256 indexed subId,
        uint256 newExpiration 
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
        uint256 priceWei = subs[id].priceWei;

        if(msg.value != priceWei) revert IncorrectValue(
            msg.value, priceWei
        );
        _;
    }

    modifier hasBalance() {
        if(balances[msg.sender] == 0) revert EmptyBalance();
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
        string memory title,
        uint256 durationDays,
        uint256 _priceWei,
        bool activate
    ) external {
        uint256 id = nextId++;

        subs[id] = Sub({
            durationSeconds: durationDays * 1 days,
            priceWei: _priceWei,
            state: activate ? SubState.Active : SubState.Paused,
            owner: msg.sender
        });

        emit SubCreated(title, msg.sender, id);
    }

    function activateSub (uint256 id) external subExists(id) isSubOwner(id){
        subs[id].state = SubState.Active;
        emit SubActivated(id);
    }

    function pauseSub (uint256 id) external subExists(id) isSubOwner(id){
        subs[id].state = SubState.Paused;
        emit SubPaused(id);
    }

    function setSubPrice(uint256 id, uint256 _priceWei) external subExists(id) isSubOwner(id) {
        subs[id].priceWei = _priceWei;
        emit SubPriceUpdated(id, _priceWei);
    }

    function setSubDuration(uint256 id, uint256 durationDays) external subExists(id) isSubOwner(id) {
        uint256 _durationSeconds = durationDays * 1 days;
        subs[id].durationSeconds = _durationSeconds;
        emit SubDurationUpdated(id, _durationSeconds);
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
        User storage user = users[receiver];
        uint256 expiresAt = user.subExpirations[id];

        if(expiresAt == 0) user.subIds.push(id);

        uint256 addSeconds = subs[id].durationSeconds;
        uint256 currentTime = block.timestamp;

        uint256 newExpiration = expiresAt > currentTime ? 
            expiresAt + addSeconds : 
            currentTime + addSeconds;

        user.subExpirations[id] = newExpiration;

        emit timeAddedToSub(receiver, id, newExpiration);
    }

    function increaseBalance (uint256 subId) private {
        balances[subs[subId].owner] += msg.value;
        contractBalance += msg.value;

        assert(contractBalance == address(this).balance);
    }

    function withdrawBalance () external hasBalance noReentrancy {
        uint256 amountToTransfer = balances[msg.sender];

        balances[msg.sender] = 0;
        contractBalance -= amountToTransfer;

        payable(msg.sender).transfer(amountToTransfer);
        
        assert(contractBalance == address(this).balance);
    }

    function viewBalance () external view returns (uint256) {
        return balances[msg.sender];
    }

    function isSubActive(uint256 id) public view subExists(id) returns(bool) {
        return subs[id].state == SubState.Active;
    }

    function isUserSubscribed(address userAddress, uint256 id) external view subExists(id) subIsActive(id) returns(bool) {
        return users[userAddress].subExpirations[id] > block.timestamp;
    }

    function getUserExpirations(address userAddress) 
        external view returns(uint256[] memory, uint256[] memory) 
    {
        User storage user = users[userAddress];
        uint256[] storage subIds = user.subIds;
        uint256 len = subIds.length;

        if(len == 0) return (new uint256[](0), new uint256[](0));

        mapping(uint256 => uint256) storage subExpirations = user.subExpirations;
        uint256 currentTime = block.timestamp;

        uint256[] memory ids = new uint256[](len);
        uint256[] memory expirations = new uint256[](len);
        uint256 activeCount = 0;

        for(uint256 i = 0; i < len; i++) {
            uint256 subId = subIds[i];
            uint256 subExpiration = subExpirations[subId];

            if(subExpiration > currentTime) {
                ids[activeCount] = subId;
                expirations[activeCount] = subExpiration; 
                unchecked {
                    activeCount++;
                }
            }
        }

        assembly {
            mstore(ids, activeCount)
            mstore(expirations, activeCount)
        }

        return(ids, expirations);
    }
}