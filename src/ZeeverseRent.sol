// SPDX-License-Identifier: UNLICENSED
// Author: shaneson.eth

pragma solidity ^0.8.13;
import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC1155.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./WrapZee.sol";

contract ZeeverseRentV1 is ReentrancyGuard {
    // focus on the zee as collateral
    address constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address private Collateral;
    uint256 public protocolFee;
    
    mapping(uint256 => RentalInfo) ZeeverseRentInfo;

    WrapZee wrapZee;

    struct RentalInfo {
        uint256 tokenId;
        uint256 secondRent;      // The fee of rent per second
        uint256 rentDeadline;    // when rentDeadline is 0, it means no occupant.
        address host;
        address occupant;
    }

    constructor (address collateral) {
        Collateral = collateral;
        wrapZee = new WrapZee("WrapZee", "WrapZee");
        
        // Default: 5%
        protocolFee = 500;
    }

    
    // [PreIssue] 1. owner => preIssue the Real Shark => get the Wrap Shark
    function preIssue(uint256 tokenId, uint256 dailyRent) public nonReentrant {
        require(dailyRent > 86400, "Too little money");

        // Add Rent Info
        RentalInfo memory rentalInfo = RentalInfo(
            tokenId,
            dailyRent/86400,
            0,
            msg.sender,
            msg.sender
        );
        ZeeverseRentInfo[tokenId] = rentalInfo;

        // Transfer Collateral
        IERC721(Collateral).safeTransferFrom(msg.sender, address(this), tokenId);

        // mint wrap token
        wrapZee.safeMint(msg.sender, tokenId);
    } 
    

    // [Rent] 2. user => Rent => Change owner, burn the Wrap Shark, and get the new Wrap Shark
    function requestRental(uint256 tokenId) public payable nonReentrant {
        RentalInfo memory rentalInfo = ZeeverseRentInfo[tokenId];

        // Check 
        require(block.timestamp > rentalInfo.rentDeadline, "Currently not available for rent");
        require(msg.value > rentalInfo.secondRent, "Too little money");
 
        // Update Rent Info
        rentalInfo.occupant = msg.sender;
        rentalInfo.rentDeadline = block.timestamp + msg.value / rentalInfo.secondRent;
        ZeeverseRentInfo[tokenId] = rentalInfo;

        // changeOccupant
        wrapZee.changeOccupant(tokenId, msg.sender);

        // Send to host
        uint256 valueAfterFee = msg.value * protocolFee / 10000;
        (bool status, ) = payable(rentalInfo.host).call{value: msg.value - valueAfterFee}("");
        require(status == true, "Send to host Fail");
    }

    // [settle] 3. owenr => burn the user's Wrap Shar, and get the Wrap Shark
    function settle(uint256 tokenId) public {
        RentalInfo memory rentalInfo = ZeeverseRentInfo[tokenId];

        // check 
        require(block.timestamp > rentalInfo.rentDeadline, "Currently not available for rent");
        require(rentalInfo.host == msg.sender, "Only host can settle");

        wrapZee.changeOccupant(tokenId, rentalInfo.host);
    }

    // [claim] 4. owner => claim the assets
    function claim(uint256 tokenId) public nonReentrant {
        RentalInfo memory rentalInfo = ZeeverseRentInfo[tokenId];

        // check 
        require(block.timestamp > rentalInfo.rentDeadline, "Currently not available for rent");
        require(rentalInfo.host == msg.sender, "Only host can claim");

        wrapZee.burn(tokenId);
        IERC721(Collateral).safeTransferFrom(address(this), msg.sender, tokenId);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    receive() external payable {}

}
