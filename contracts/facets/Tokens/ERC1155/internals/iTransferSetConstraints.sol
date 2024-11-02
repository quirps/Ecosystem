pragma solidity ^0.8.9;

import {LibERC1155TransferConstraints} from "../libraries/LibERC1155TransferConstraints.sol";

contract iTransferSetConstraints {
    
    function setTransferLimit(uint256 ticketId, LibERC1155TransferConstraints.TransferLimit memory _tranfserLimit) internal {

    }
    function setExpireable(uint256) external{

    }

/**
Would like to clean this function up at some point.
 */
    function ticketConstraintHandler(LibERC1155TransferConstraints.Constraints memory _constraints) internal returns (uint256){
        LibERC1155TransferConstraints.ConstraintStorage storage cs = LibERC1155TransferConstraints.erc1155ConstraintStorage();
        //check isActive to determine which ticketId interval it's in 
        uint64 bitMap; 
        uint192 nonce;
        uint192 incrementedNonce;
        uint256 ticketId;
        if(_constraints.transferLimit.isActive){
            //transferLimitConditions set
            bitMap ^= (1 << 0);
        }
        if(_constraints.memberRankDependency.isActive){
            //memberRankDependency set
            bitMap ^= (1 << 1);
        }
        if(_constraints.expireable.isActive){
            //expireable set
            bitMap ^= (1 << 2);
        }
        
        //get nonce
        nonce = cs.ticketIntervalNonce[ bitMap ];
        incrementedNonce = nonce + 1;
        //generate ticket id 
        ticketId = (incrementedNonce ) +  bitMap * LibERC1155TransferConstraints.INTERVAL_SIZE;
        
        cs.ticketIntervalNonce[bitMap] = incrementedNonce;
        

        //store ticket constraints
        if(_constraints.transferLimit.isActive){
            cs.tranfserLimit[ticketId] = _constraints.transferLimit.maxTransfers;
        }
        if(_constraints.memberRankDependency.isActive){
            cs.minimumMemberRank[ticketId] = _constraints.memberRankDependency.minimumRank;
        }
        if(_constraints.expireable.isActive){
            cs.expireTime[ticketId] = _constraints.expireable.expireTime;
        }

        return ticketId;
    }

}

/**
 */