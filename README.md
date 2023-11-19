
# ZeeverseRent


During my free time after work, I have been thinking a lot about how to help release liquidity for NFTs in Zeeverse. As the game grows increasingly popular and the prices of legendary equipment skyrocket, a new problem arises here：**Users cannot afford to purchase a legendary Zee/Equipment, but they can afford the cost of short-term rentals, such as for 1 or 2 days; While the holders are also unwilling to sell.** I have come up with the idea of creating a rental contract service for Zeeverse, called ZeeverseRent, to address the lending issue that typically requires over-collateralization.

Sincerely,

Shaneson.eth


# Depoly

```
forge script script/deploy.s.sol:ZeeverRentDeploy --fork-url https://arb1.arbitrum.io/rpc --broadcast --verify -vvvv 
```

# Test
```
forge test
```