// SPDX-License-Identifier: UNLICENSED
// Author: shaneson.eth
pragma solidity ^0.8.17;

import {Test} from "lib/forge-std/src/Test.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "src/Zee/ZeeverseZeeRent.sol";

import "lib/forge-std/src/console2.sol";

contract ZeeverseRentTesting is Test {
    address shaneson = 0x790ac11183ddE23163b307E3F7440F2460526957;
    address ZEE = 0x094fA8aE08426AB180e71e60FA253B079E13B9FE;
    uint256 tokenID = 1253;
    ZeeverseZeeRentV1 zeeverseRentV1;
    address WrapZeeTest;

    function setUp() public {
         vm.createSelectFork(vm.envString("ARB_RPC_URL"));
         zeeverseRentV1 = new ZeeverseZeeRentV1(ZEE);
         WrapZeeTest = zeeverseRentV1.getWrapZeeAddress();
    }

    // 1. preIssue
    function test0() public {
        vm.startPrank(shaneson);
        IERC721(ZEE).approve(address(zeeverseRentV1), tokenID);
        zeeverseRentV1.preIssue(tokenID, 0.0000001 ether);

        // check
        require(IERC721(ZEE).ownerOf(tokenID) == address(zeeverseRentV1), "check0");
        require(IERC721(WrapZeeTest).ownerOf(tokenID) == address(shaneson), "check1");
        vm.stopPrank();
    }

    // 1. preIssue
    // 2. Rent
    function test1() public {
        test0();
        address buyer = 0xDe1820F69B3022b8C3233d512993EBA8cFf29EbB;
        uint256 shaneson_balance_0 = payable(shaneson).balance;

        vm.startPrank(buyer);
        zeeverseRentV1.requestRental{value: 0.001 ether}(tokenID);

        uint256 shaneson_balance_1 = payable(shaneson).balance;

        // check
        require(IERC721(ZEE).ownerOf(tokenID) == address(zeeverseRentV1), "check2");
        require(IERC721(WrapZeeTest).ownerOf(tokenID) == address(buyer), "check3");
        require(zeeverseRentV1.getDeadLine(tokenID) == block.timestamp + 10000 , "check4");
        require(shaneson_balance_1  == shaneson_balance_0 + 0.00095 ether, "check5");

        vm.stopPrank();
    }

    // 1. preIssue
    // 2. Rent
    // 3. Rent
    function test2_RentByOther() public {
        test1();

        uint256 now_timestamp = block.timestamp;
        vm.warp(now_timestamp + 10001);

        address buyer = 0x399EfA78cAcD7784751CD9FBf2523eDf9EFDf6Ad;
        uint256 shaneson_balance_0 = payable(shaneson).balance;

        vm.startPrank(buyer);
        zeeverseRentV1.requestRental{value: 0.001 ether}(tokenID);

        uint256 shaneson_balance_1 = payable(shaneson).balance;

        // check
        require(IERC721(ZEE).ownerOf(tokenID) == address(zeeverseRentV1), "check6");
        require(IERC721(WrapZeeTest).ownerOf(tokenID) == address(buyer), "check7");
        require(zeeverseRentV1.getDeadLine(tokenID) == block.timestamp + 10000 , "check8");
        require(shaneson_balance_1  == shaneson_balance_0 + 0.00095 ether, "check9");

        vm.stopPrank();
    }

    // 1. preIssue
    // 2. Rent
    // 3. claim
    function test3() public {
        test1();

        uint256 now_timestamp = block.timestamp;
        vm.warp(now_timestamp + 10001);

        vm.startPrank(shaneson);
        zeeverseRentV1.claim(tokenID);

        // check
        require(IERC721(ZEE).ownerOf(tokenID) == shaneson, "check16");
        require(zeeverseRentV1.getDeadLine(tokenID) == 0 , "check17");
        require(IERC721(WrapZeeTest).balanceOf(0x399EfA78cAcD7784751CD9FBf2523eDf9EFDf6Ad) == 0, "check18");
        require(IERC721(WrapZeeTest).balanceOf(0xDe1820F69B3022b8C3233d512993EBA8cFf29EbB) == 0, "check19");
        require(IERC721(WrapZeeTest).balanceOf(shaneson) == 0, "check20");

        vm.stopPrank();
    }

    // 1. preIssue
    // 2. Rent
    // 3. claim
    // 4. preIssue
    function test4() public {
        test3();
        test0();
    }

}