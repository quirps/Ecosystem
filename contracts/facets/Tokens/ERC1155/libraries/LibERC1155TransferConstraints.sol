pragma solidity ^0.8.9;

import {LibMemberLevel} from "../../../MemberLevel/LibMemberLevel.sol";
library LibERC1155TransferConstraints {
    bytes32 constant ERC1155_CONSTRAINT_STORAGE_POSITION = keccak256("diamond.erc1155constraints");

    struct ConstraintStorage {
        mapping(uint256 => bool) transferrable;
        mapping(uint256 => int64) minimumMemberLevel;
        mapping(uint256 => uint32) expireTime;
        mapping(uint256 => uint24) royaltyFee;
        mapping(uint128 => uint128) ticketIntervalNonce;
    }

    function erc1155ConstraintStorage() internal pure returns (ConstraintStorage storage cs) {
        bytes32 position = ERC1155_CONSTRAINT_STORAGE_POSITION;
        assembly {
            cs.slot := position
        }
    }
    uint256 constant INTERVAL_SIZE = 2 ** 128;
    uint256 constant NUMBER_INTERVALS = 2 ** 128; // max 60 constraints
    uint8 constant CURRENT_MAX_INTERVALS = 8;
    struct Constraints {
        bool isTransferable;
        int64 minimumMembershipLevel;
        bool isMembershipLevelActive;
        uint32 expireTime;
        uint24 royaltyFee;
    }


    //Blacklist contained in MemberRankDependency, rank 0 is blacklist,
    //set min rank as 1 or greater

    // struct MemberRankTieredDelay{
    //     LibMembers.rank minimumRank;
    // }
}
