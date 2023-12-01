// SPDX-License-Identifier: UNLICENSED
// Author: shaneson.eth

pragma solidity ^0.8.13;

contract ZeeverseConstant {
    address constant NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address constant ADMIN = 0x790ac11183ddE23163b307E3F7440F2460526957;
    uint256 constant NEED_INIT = 0;

    uint256 constant INITIAL_DDL = 0;
    uint256 constant PROTOCOL_FEE = 500;
    uint256 constant MIN_MAX_DURATION = 39600;

    address public constant ZEE_COLLATERAL = 0x094fA8aE08426AB180e71e60FA253B079E13B9FE;
    address public constant EQUIPMENT_COLLATERAL = 0x58318BCeAa0D249B62fAD57d134Da7475e551B47;

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
        uint256 maxDuration;     // The max duration of second
        address host;
        address occupant;
        WrapType wrapType;
    }
}