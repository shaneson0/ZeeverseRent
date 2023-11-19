// SPDX-License-Identifier: UNLICENSED
// Author: shaneson.eth

pragma solidity ^0.8.13;
import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC1155.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import "./WrapZee.sol";

contract ZeeverseRentV1 is ReentrancyGuard, Ownable {
    address constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address constant ADMIN = 0x790ac11183ddE23163b307E3F7440F2460526957;
    uint256 constant INITIAL_DDL = 0;
    uint256 constant PROTOCOL_FEE = 500;
    address private Collateral;
    uint256 public protocolFee;
    
    mapping(uint256 => RentalInfo) ZeeverseRentInfo;
    WrapZee public wrapZee;

    struct RentalInfo {
        uint256 tokenId;
        uint256 secondRent;      // The fee of rent per second
        uint256 rentDeadline;    // when rentDeadline is 0, it means no occupant.
        address host;
        address occupant;
    }

    constructor (address collateral) Ownable(ADMIN) {
        Collateral = collateral;
        protocolFee = PROTOCOL_FEE;
        wrapZee = new WrapZee("WrapZee", "WrapZee");
    }

    function getWrapZeeAddress() public view returns(address) {
        return address(wrapZee);
    }

    function getDeadLine(uint256 tokenId) public view returns(uint256) {
        return (ZeeverseRentInfo[tokenId]).rentDeadline;
    }
    
    function preIssue(uint256 tokenId, uint256 secondRent) public nonReentrant {
        require(secondRent > 0, "SecondRent can't not be zero");
        require(msg.sender == IERC721(Collateral).ownerOf(tokenId), "Msg.sender do not own the NFT");

        // Add Rent Info
        RentalInfo memory rentalInfo = RentalInfo(
            tokenId,
            secondRent,
            INITIAL_DDL,
            msg.sender,
            msg.sender
        );
        ZeeverseRentInfo[tokenId] = rentalInfo;

        // Transfer Collateral
        IERC721(Collateral).safeTransferFrom(msg.sender, address(this), tokenId);

        // mint wrap token
        wrapZee.safeMint(msg.sender, tokenId);
    } 
    

    function requestRental(uint256 tokenId) public payable nonReentrant {
        RentalInfo memory rentalInfo = ZeeverseRentInfo[tokenId];

        // Check 
        require(block.timestamp > rentalInfo.rentDeadline, "Currently not available for rent");
        require(msg.value > rentalInfo.secondRent, "Too little money");
        require(rentalInfo.tokenId == tokenId, "Invalid tokenId in mapping");
 
        // Update Rent Info
        rentalInfo.occupant = msg.sender;
        rentalInfo.rentDeadline = block.timestamp + msg.value / rentalInfo.secondRent;
        ZeeverseRentInfo[tokenId] = rentalInfo;

        // change occupant
        wrapZee.changeOccupant(tokenId, msg.sender);

        // Send rent fee to host
        uint256 valueAfterFee = msg.value * protocolFee / 10000;
        (bool status, ) = payable(rentalInfo.host).call{value: msg.value - valueAfterFee}("");
        require(status == true, "Send to host Fail");
    }


    function claim(uint256 tokenId) public nonReentrant {
        RentalInfo memory rentalInfo = ZeeverseRentInfo[tokenId];

        // check 
        require(block.timestamp > rentalInfo.rentDeadline, "Currently not available for rent");
        require(rentalInfo.host == msg.sender, "Only host can claim");
        require(rentalInfo.tokenId == tokenId, "Invalid tokenId in mapping");

        // Delete Rent Info
        delete rentalInfo;
        delete ZeeverseRentInfo[tokenId];

        // Burn wrap token, and send collectrals to user
        wrapZee.burn(msg.sender, tokenId);
        IERC721(Collateral).safeTransferFrom(address(this), msg.sender, tokenId);
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function withdrawFee() public onlyOwner {
        (bool result,) = payable(ADMIN).call{value: address(this).balance}("");
        require(result, "withdraw fee");
    }

    receive() external payable {}

}
