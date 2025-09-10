# SmartSub
A subscription platform smartcontract that allows users to create subscriptions and to buy subscriptions. 

## Of-chain indexing
In order to save gas, of-chain indexing is required.
Creation of new subscriptions and changes to existing subscriptions are emitted as events which can be used of-chain to maintain a up-to-date list of available products and their information.  
