// SPDX-License-Identifier: UNLICENSED
// Author: shaneson.eth

pragma solidity ^0.8.13;
import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC1155.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "lib/forge-std/src/console2.sol";

import "./ZeeverseConstant.sol";
import "./WrapZee.sol";

contract ZeeverseZeeRentV1 is ZeeverseConstant, ReentrancyGuard, Ownable {


    uint256 public protocolFee;
    
    // mapping(uint256 => IOUInfo) ZeeverseIOUInfo;
    ZeeWrapAsset public zeeWrapAsset;

    constructor () Ownable(ADMIN) {
        protocolFee = PROTOCOL_FEE;
        zeeWrapAsset = new ZeeWrapAsset("WrapZee", "WrapZee");
    }

    // ================================= view =================================

    function getWrapZeeAddress() public view returns(address) {
        return address(zeeWrapAsset);
    }
    
    // ================================= admin =================================

    event UpdateFee(uint256 fee);
    event WithdrawFee();

    function updateProtocolFee(uint256 fee) public onlyOwner {
        require(fee < 10000, "fee need to small than 10000");
        protocolFee = fee;
        emit UpdateFee(protocolFee);
    }

    function withdrawFee() public onlyOwner {
        (bool result,) = payable(ADMIN).call{value: address(this).balance}("");
        require(result, "withdraw fee");
        emit WithdrawFee();
    }

    // ================================= main =================================
    
    function issueZee(uint256 tokenId, uint256 secondRent, uint256 maxDuration) public nonReentrant returns (uint256 wrapId) {
        require(msg.sender == IERC721(ZEE_COLLATERAL).ownerOf(tokenId), "Msg.sender do not own the NFT");
        require(maxDuration > MIN_MAX_DURATION, "maxDuration need to longer that 11hours");

        // Add Rent Info
        IOUInfo memory iouInfo = IOUInfo(
            NEED_INIT,
            tokenId,
            1, 
            secondRent,
            INITIAL_DDL,
            maxDuration,
            msg.sender,
            msg.sender,
            WrapType.ZEE
        );

        // Transfer Collateral
        IERC721(ZEE_COLLATERAL).safeTransferFrom(msg.sender, address(this), tokenId);

        // mint wrap token
        wrapId = zeeWrapAsset.safeMint(iouInfo);
    }

    function requestRental(uint256 wrapId) public payable nonReentrant {
        address newOccupant = msg.sender;
        uint256 newRentDeadline = zeeWrapAsset.getNewRentDeadline(wrapId, msg.value);

        // change occupant
        address host = zeeWrapAsset.changeOccupant(wrapId, newOccupant, newRentDeadline, msg.value);

        // Send rent fee to host
        uint256 valueAfterFee = msg.value * protocolFee / 10000;
        
        (bool status, ) = payable(host).call{value: msg.value - valueAfterFee}("");
        require(status == true, "Send to host Fail");
    }

    // Burn wrap token, and send collectrals to user
    function claim(uint256 wrapId) public nonReentrant {
        uint256 tokenId = zeeWrapAsset.burn(msg.sender, wrapId);
        IERC721(ZEE_COLLATERAL).safeTransferFrom(address(this), msg.sender, tokenId);
    }


    // ================================= CallBack =================================

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    receive() external payable {}

}
