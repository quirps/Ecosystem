pragma solidity ^0.8.9; 

import {LibMembers} from "../../../MemberRankings/LibMembers.sol"; 

library LibERC1155TransferConstraints{
    struct Constraints{
        TransferLimit transferLimit;
        MemberRankDependency memberRankDependency;
        Expireable expireable;
    }

    struct TransferLimit{
        uint256 maxTransfers;
        bool isActive;
    }

    struct MemberRankDependency{
        LibMembers.rank minimumRank;
        bool isActive;
    }

    //Blacklist contained in MemberRankDependency, rank 0 is blacklist, 
    //set min rank as 1 or greater
    struct Expireable{
        uint32 expireTime;
        bool isActive;
    }

}