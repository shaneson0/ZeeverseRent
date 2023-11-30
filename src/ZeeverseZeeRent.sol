// SPDX-License-Identifier: UNLICENSED
// Author: shaneson.eth

pragma solidity ^0.8.13;
import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC1155.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "lib/forge-std/src/console2.sol";


import "./WrapZee.sol";
import "./IOU.sol";

contract ZeeverseZeeRentV1 is IOU, ReentrancyGuard, Ownable {
    address constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address constant ADMIN = 0x790ac11183ddE23163b307E3F7440F2460526957;
    uint256 constant NEED_INIT = 0;

    uint256 constant INITIAL_DDL = 0;
    uint256 constant PROTOCOL_FEE = 500;

    address public constant ZEE_COLLATERAL = 0x094fA8aE08426AB180e71e60FA253B079E13B9FE;
    address public constant EQUIPMENT_COLLATERAL = 0x58318BCeAa0D249B62fAD57d134Da7475e551B47;

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
    
    function issueZee(uint256 tokenId, uint256 secondRent) public nonReentrant returns (uint256 wrapId) {
        require(secondRent > 0, "SecondRent can't not be zero");
        require(msg.sender == IERC721(ZEE_COLLATERAL).ownerOf(tokenId), "Msg.sender do not own the NFT");

        // Add Rent Info
        IOUInfo memory iouInfo = IOUInfo(
            NEED_INIT,
            tokenId,
            1, 
            secondRent,
            INITIAL_DDL,
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
        IOUInfo memory iouInfo = zeeWrapAsset.getIOUInfo(wrapId);

        // Check 
        require(block.timestamp > iouInfo.rentDeadline, "Currently not available for rent");
        require(msg.value > iouInfo.secondRent, "Too little money");
 
        // Update Rent Info
        iouInfo.occupant = msg.sender;
        iouInfo.rentDeadline = block.timestamp + msg.value / iouInfo.secondRent;

        // change occupant
        zeeWrapAsset.changeOccupant(iouInfo);

        // Send rent fee to host
        uint256 valueAfterFee = msg.value * protocolFee / 10000;
        (bool status, ) = payable(iouInfo.host).call{value: msg.value - valueAfterFee}("");
        require(status == true, "Send to host Fail");
    }


    function claim(uint256 wrapId) public nonReentrant {
        IOUInfo memory iouInfo = zeeWrapAsset.getIOUInfo(wrapId);

        // check state
        require(block.timestamp > iouInfo.rentDeadline, "Currently not available for rent");
        require(iouInfo.host == msg.sender, "Only host can claim");

        // Burn wrap token, and send collectrals to user
        zeeWrapAsset.burn(msg.sender, iouInfo.wrapId);
        IERC721(ZEE_COLLATERAL).safeTransferFrom(address(this), msg.sender, iouInfo.tokenId);
    }


    // ================================= CallBack =================================

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    receive() external payable {}

}
