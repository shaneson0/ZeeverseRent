// SPDX-License-Identifier: UNLICENSED
// Author: shaneson.eth
pragma solidity ^0.8.17;
import "lib/forge-std/src/Script.sol";
import "lib/forge-std/src/console2.sol";
import "src/ZeeverseZeeRent.sol";

contract ZeeverRentDeploy is Script {

    // forge script script/deploy.s.sol:ZeeverRentDeploy --fork-url https://arb1.arbitrum.io/rpc --broadcast --verify -vvvv 
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        ZeeverseZeeRentV1 zeeverseRentV1 = new ZeeverseZeeRentV1();
        address WrapZeeTest = zeeverseRentV1.getWrapZeeAddress();
        
        console2.log( "zeeverseRentV1: ", address(zeeverseRentV1));
        console2.log( "WrapZeeTest: ", WrapZeeTest);

        vm.stopBroadcast();
    }

}