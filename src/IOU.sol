pragma solidity ^0.8.21;

abstract contract IOU {
    enum WrapType {
        ZEE,
        EQUIPMENT
    }

    struct IOUInfo {
        uint256 wrapId;
        uint256 tokenId;
        uint256 amount;
        uint256 secondRent;      // The fee of rent per second
        uint256 rentDeadline;    // when rentDeadline is 0, it means no occupant.
        address host;
        address occupant;
        WrapType wrapType;
    }
}