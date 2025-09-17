# SmartSub
A subscription platform smartcontract that allows users to create subscriptions and to buy subscriptions. 

## Gas optimizations
1. Implemented re-usable modifiers that uses if statements with reverts and custom errors in order to save gas compared to require. (Exceptions in two places where a require and assert was used in order to meet assignment criteria).

2. Cache data in memory instead of making multiple fetches from storage. 

3. Only use public where absolutely necessary, save gas by utlizing private / internal / external where possible. 

4. Use mappings instead of array's where applicable. 

5. When filtering arrays on a criteria before returning them, instead of using double pass where matches are first counted before declaring the arrays of correct size, i declared the arrays of max size and then use assembly mstore in order to truncate the array to the size of active subscriptions counted. 
    * Double pass: 33175 gas
    * Single pass: 29455 gas



## Notes on gas optimization

The use of events negates the need for the following implementations that has been made, they were included in order to meet assignment criteria: 

1. Array in the user struct that maintains a list of subscription id's, these can be indexed of-chain through the timeAddedToSub event

2. Functions isUserSubscribed and getUserExpirations are not needed since this can be found out of-chain through the emited event timeAddedToSub. 


## Notes on security

1. Use call with revert instead of transfer in order to properly calculate gas and avoid tx failure  
    * Avoid: ```payable(owner).transfer(amountToTransfer);``` 
    * Use: ```(bool ok, ) = payable(recipient).call{value: amount}(""); ```  