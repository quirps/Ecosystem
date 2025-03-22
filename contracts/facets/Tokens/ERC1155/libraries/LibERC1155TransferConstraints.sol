pragma solidity ^0.8.9; 

import {LibMemberLevel } from "../../../MemberLevel/LibMemberLevel.sol"; 
library LibERC1155TransferConstraints{
    bytes32 constant ERC1155_CONSTRAINT_STORAGE_POSITION = keccak256("diamond.erc1155constraints");

struct ConstraintStorage{
    mapping(uint256 => uint256) tranfserLimit; 
    mapping(uint256 => uint32) minimumMemberLevel; 
    mapping(uint256 => uint32) expireTime;
    mapping(uint128  => uint128) ticketIntervalNonce;
} 
 
function erc1155ConstraintStorage() internal pure returns (ConstraintStorage storage cs) {
        bytes32 position = ERC1155_CONSTRAINT_STORAGE_POSITION;
        assembly {
            cs.slot := position 
        }  
    }
    uint256 constant INTERVAL_SIZE = 2**128; 
    uint256 constant NUMBER_INTERVALS = 2**128; // max 60 constraints
    uint8 constant CURRENT_MAX_INTERVALS = 8;
    struct Constraints{
        TransferLimit transferLimit;
        MemberLevelDependency minimumMembershipLevel;
        Expireable expireable;
    }

    struct TransferLimit{
        uint256 maxTransfers;
        bool isActive;
    }
 
    struct MemberLevelDependency{
        uint32 minimumLevel;
        bool isActive;
    }

    //Blacklist contained in MemberRankDependency, rank 0 is blacklist, 
    //set min rank as 1 or greater
    struct Expireable{
        uint32 expireTime;
        bool isActive;
    }

    // struct MemberRankTieredDelay{
    //     LibMembers.rank minimumRank;
    // }
}