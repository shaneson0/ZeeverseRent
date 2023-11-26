pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract WrapZee is ERC721, Ownable {

    mapping(uint256 => address) Host;
    constructor(
        string memory name_,
        string memory symbol_
    ) ERC721(name_, symbol_) Ownable(msg.sender) {
    }

    function safeMint(address host, uint256 tokenId) public onlyOwner {
        require(balanceOf(host) == 0, "address(0) is invalid");
        Host[tokenId] = host;
        _safeMint(host, tokenId);
    }

    function changeOccupant(uint256 tokenId, address newOccupant) external onlyOwner {
        _update(newOccupant, tokenId, ownerOf(tokenId));
    }

    function burn(address requestUser, uint256 tokenId) public onlyOwner {
        require(requestUser == Host[tokenId]);
        _update(address(0), tokenId, ownerOf(tokenId));
    }


}