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

    function getIOUInfo(uint256 wrapId) external view returns (IOUInfo memory) {
        return wrapAssets[wrapId];
    }

    function getDeadLine(uint256 wrapId) public view returns(uint256 ddl) {
        IOUInfo memory iouInfo = wrapAssets[wrapId];
        return iouInfo.rentDeadline;
    }

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

    function changeOccupant(IOUInfo memory iouInfo) external onlyOwner {
        // update state
        wrapAssets[iouInfo.wrapId] = iouInfo;

        // change owner
        _update(iouInfo.occupant, iouInfo.wrapId, ownerOf(iouInfo.wrapId));
    }

    function burn(address requestUser, uint256 wrapId) public onlyOwner {
        // check state
        IOUInfo memory iouInfo = wrapAssets[wrapId];
        require(requestUser == iouInfo.host);
        require(ownerOf(iouInfo.wrapId) == iouInfo.occupant, "owner of wrapId is not occupant");

        // update state
        _update(address(0), iouInfo.wrapId, ownerOf(wrapId));
    }


}