// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.28;

contract SmartSub {

    uint256 private nextId;
    uint256 private owedBalance;
    bool private locked;

    enum SubState {Active, Paused}

    struct Sub {
        string title;
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
    event TimeAddedToSub(
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
    error TransferFailed(uint256 amountWei, address recipient);


    modifier subExistsAndIsOwner(uint256 id) {
        address owner = subs[id].owner;
        if(owner == address(0)) revert SubscriptionNotFound();
        if(owner != msg.sender) revert NotOwner(msg.sender);
        _;
    }

    modifier subExists(uint256 id) {
        if(subs[id].owner == address(0)) revert SubscriptionNotFound();
        _;
    }

    modifier subExistsAndIsActive(uint256 id) {
        Sub storage sub = subs[id];
        if(sub.owner == address(0)) revert SubscriptionNotFound();
        if(sub.state == SubState.Paused) revert SubscriptionPaused();
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
        string memory _title,
        uint256 durationSeconds,
        uint256 _priceWei,
        bool activate
    ) external {
        uint256 id = nextId++;

        subs[id] = Sub({
            title: _title,
            durationSeconds: durationSeconds,
            priceWei: _priceWei,
            state: activate ? SubState.Active : SubState.Paused,
            owner: msg.sender
        });

        emit SubCreated(_title, msg.sender, id);
    }

    function activateSub (uint256 id) external subExistsAndIsOwner(id){
        subs[id].state = SubState.Active;
        emit SubActivated(id);
    }

    function pauseSub (uint256 id) external subExistsAndIsOwner(id){
        subs[id].state = SubState.Paused;
        emit SubPaused(id);
    }

    function setSubPrice(uint256 id, uint256 priceWei) external subExistsAndIsOwner(id) {
        subs[id].priceWei = priceWei;
        emit SubPriceUpdated(id, priceWei);
    }

    function setSubDuration(uint256 id, uint256 durationSeconds) external subExistsAndIsOwner(id) {
        subs[id].durationSeconds = durationSeconds;
        emit SubDurationUpdated(id, durationSeconds);
    }


    function buySub (uint256 id) external payable subExistsAndIsActive(id) {
        Sub storage sub = subs[id];
        uint256 received = msg.value;
        uint256 price = sub.priceWei;

        if(received != price) revert IncorrectValue(received, price);

        addTime(msg.sender, id, sub);
        increaseBalance(sub);
    }

    function giftSub (address receiver, uint256 id) external payable subExistsAndIsActive(id) {
        Sub storage sub = subs[id];
        uint256 received = msg.value;
        uint256 price = sub.priceWei;

        if(received != price) revert IncorrectValue(received, price);

        addTime(receiver, id, sub);
        increaseBalance(sub);
    }

    function addTime (address receiver, uint256 id, Sub storage sub) private {
        User storage user = users[receiver];
        uint256 expiresAt = user.subExpirations[id];

        if(expiresAt == 0) user.subIds.push(id);

        uint256 addSeconds = sub.durationSeconds;
        uint256 currentTime = block.timestamp;

        uint256 newExpiration = expiresAt > currentTime ? 
            expiresAt + addSeconds : 
            currentTime + addSeconds;

        user.subExpirations[id] = newExpiration;

        emit TimeAddedToSub(receiver, id, newExpiration);
    }

    function increaseBalance (Sub storage sub) private {
        balances[sub.owner] += msg.value;
        owedBalance += msg.value;

        assert(owedBalance <= address(this).balance);
    }

    function withdrawBalance () external hasBalance noReentrancy {
        uint256 amountToTransfer = balances[msg.sender];

        balances[msg.sender] = 0;
        owedBalance -= amountToTransfer;
        transferEth(amountToTransfer);
        
        assert(owedBalance <= address(this).balance);
    }

    function transferEth(uint256 amount) private {
        address recipient = msg.sender;

        (bool ok, ) = payable(recipient).call{value: amount}("");
        if(!ok) revert TransferFailed(amount, recipient);
    }

    function viewBalance () external view returns (uint256) {
        return balances[msg.sender];
    }

    function isSubActive(uint256 id) external view returns(bool){
        Sub storage sub = subs[id];

        if(sub.owner == address(0)) revert SubscriptionNotFound();
        return sub.state == SubState.Active;
    }

    function isUserSubscribed(address userAddress, uint256 id) external view subExists(id) returns(bool) {
        uint256 expiration = users[userAddress].subExpirations[id];

        return expiration == 0 ? false : expiration > block.timestamp;
    }

    function getActiveSubs(address userAddress) 
        external view returns(string[] memory, uint256[] memory, uint256[] memory) 
    {
        User storage user = users[userAddress];
        uint256[] storage subIds = user.subIds;
        uint256 len = subIds.length;

        if(len == 0) return (new string[](0), new uint256[](0), new uint256[](0));

        uint256 currentTime = block.timestamp;

        string[] memory titles = new string[](len);
        uint256[] memory ids = new uint256[](len);
        uint256[] memory expirations = new uint256[](len);
        uint256 activeCount = 0;

        for(uint256 i = 0; i < len; i++) {
            uint256 subId = subIds[i];
            uint256 subExpiration = user.subExpirations[subId];

            if(subExpiration > currentTime) {
                titles[activeCount] = subs[subId].title;
                ids[activeCount] = subId;
                expirations[activeCount] = subExpiration; 
                unchecked {
                    activeCount++;
                }
            }
        }

        assembly {
            mstore(titles, activeCount)
            mstore(ids, activeCount)
            mstore(expirations, activeCount)
        }

        return(titles, ids, expirations);
    }
}