pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IOU.sol";

contract ZeeWrapAsset is ERC721, IOU, Ownable {

    uint256 WRAPID;
    mapping(uint256 => IOUInfo)  wrapAssets;

    constructor(
        string memory name_,
        string memory symbol_
    ) ERC721(name_, symbol_) Ownable(msg.sender) {
        WRAPID = 0;
    }

    // ================================= view =================================

    function getNewRentDeadline(uint256 wrapId, uint256 totalCost) external view returns (uint256) {
        IOUInfo memory iouInfo = wrapAssets[wrapId];
        uint256 newRentDeadline =  block.timestamp + totalCost / iouInfo.secondRent;
        return newRentDeadline;
    }

    function getSecondRent(uint256 wrapId) external view returns (uint256) {
        IOUInfo memory iouInfo = wrapAssets[wrapId];
        return iouInfo.secondRent;    
    }

    function getDeadLine(uint256 wrapId) public view returns(uint256) {
        IOUInfo memory iouInfo = wrapAssets[wrapId];
        return iouInfo.rentDeadline;
    }

    // ================================= onlyOwner =================================

    function safeMint(IOUInfo memory iouInfo) public onlyOwner returns (uint256){
        // check  mint state
        require(balanceOf(iouInfo.host) == 0, "host(0) is invalid");
        require(balanceOf(iouInfo.occupant) == 0, "occupant(0) is invalid");
        require(iouInfo.secondRent > 0, "SecondRent can't not be zero");
        require(iouInfo.maxDuration > 0, "maxDuration can't not be zero");

        // update state
        iouInfo.wrapId = WRAPID;
        wrapAssets[WRAPID] = iouInfo;

        _safeMint(iouInfo.host, WRAPID);
        WRAPID = WRAPID +1;

        return iouInfo.wrapId;
    }

    function changeOccupant(uint256 wrapId, address newOccupant, uint256 newRentDeadline, uint256 totalCost) external onlyOwner returns(address) {
        IOUInfo memory iouInfo = wrapAssets[wrapId];
        require(totalCost > iouInfo.secondRent, "Too little money");
        require(block.timestamp + iouInfo.maxDuration >= newRentDeadline, "Can't exceed the max duration");
        require(block.timestamp > iouInfo.rentDeadline, "Currently not available for rent");

        // update state
        iouInfo.occupant = newOccupant;
        iouInfo.rentDeadline = newRentDeadline;
        wrapAssets[iouInfo.wrapId] = iouInfo;

        // change owner
        _update(iouInfo.occupant, iouInfo.wrapId, ownerOf(iouInfo.wrapId));
        return iouInfo.host;
    }

    function burn(address requestUser, uint256 wrapId) public onlyOwner returns (uint256) {
        // check state
        IOUInfo memory iouInfo = wrapAssets[wrapId];
        require(requestUser == iouInfo.host, "only host can claim");
        require(ownerOf(iouInfo.wrapId) == iouInfo.occupant, "owner of wrapId is not occupant");
        require(block.timestamp > iouInfo.rentDeadline, "Currently not available for rent");

        // update state
        _update(address(0), iouInfo.wrapId, ownerOf(wrapId));
        return iouInfo.tokenId;
    }


}