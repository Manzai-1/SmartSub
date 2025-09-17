# SmartSub
A subscription platform smartcontract that allows users to create subscriptions and to buy subscriptions. 

## Gas optimizations
1. Implemented re-usable modifiers that uses if statements with reverts and custom errors in order to save gas compared to require. (Exceptions in two places where a require and assert was used in order to meet assignment criteria).

2. Save on SLOADs by combining modifiers that require the same checks and are called by single functions.
Example 
    * Avoid: ```function setSubPrice(uint256 id, uint256 priceWei) external subExists(id) IsOwner(id)```
    * Use: ```function setSubPrice(uint256 id, uint256 priceWei) external subExistsAndIsOwner(id)```

3. Cache data in memory instead of making multiple fetches from storage, also send storage pointers as arguments instead of setting them multiple times when calling functions that needs the same data. 

4. Only use public where absolutely necessary, save gas by utlizing private / internal / external where possible. 

5. Use mappings instead of array's where applicable. 

6. When filtering arrays on a criteria before returning them, instead of using double pass where matches are first counted before declaring the arrays of correct size, i declared the arrays of max size and then use assembly mstore in order to truncate the array to the size of active subscriptions counted.
    * Difference in gas having 5 elements where 1 should be excluded:
        * Double pass: ```33175``` gas
        * Single pass: ```29455``` gas



## Notes on gas optimization

The use of events negates the need for the following implementations that has been made, they were included in order to meet assignment criteria: 

1. Array in the user struct that maintains a list of subscription id's, these can be indexed of-chain through the timeAddedToSub event

2. Functions isUserSubscribed and getUserExpirations are not needed since this can be found out of-chain through the emited event timeAddedToSub. 


## Notes on security

1. Use call with revert instead of transfer in order to properly calculate gas and avoid tx failure 
    * Avoid: ```payable(owner).transfer(amountToTransfer);``` 
    * Use: ```(bool ok, ) = payable(recipient).call{value: amount}(""); ```  

2. Guard against re-entrancy with a modifier that locks until the call has excecuted, this hinders malicious actors to make multiple withdraw requests in order to withdraw more than what is allocated to them. 