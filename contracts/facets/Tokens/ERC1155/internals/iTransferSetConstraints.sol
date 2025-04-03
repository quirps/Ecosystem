pragma solidity ^0.8.9;

import {LibERC1155TransferConstraints} from "../libraries/LibERC1155TransferConstraints.sol";
import { iOwnership } from "../../../Ownership/_Ownership.sol";
import { iMembers } from "../../../MemberLevel/_Members.sol" ;   
/**
 * @title  
 * @author 
 * @notice Future update will enable these constraints to have different addresess other than owner 
 */
contract  iTransferSetConstraints is iOwnership, iMembers {
    error NonTransferableError(address from, address to, uint256 ticketId);
    //Transfer limit only applies to when from is non-zero and not creator and to is not the consumer address
    function nonTransferable( address from, address to, uint256 ticketId) internal view {
        address _ecosystemOwner = _ecosystemOwner();
        if( from == address(0) || from == _ecosystemOwner ){
            //pass
        }
        else if( to == _ecosystemOwner ){  
            //pass
        }
        else{
            revert NonTransferableError(from, to, ticketId);    
        }
        
    }
    function minimumMembershipLevel(uint256 ticketId, address to) internal view {
        LibERC1155TransferConstraints.ConstraintStorage storage cs = 
        LibERC1155TransferConstraints.erc1155ConstraintStorage();
        int64 _memberLevel = _getMemberLevel( to ); 
 
        if( cs.minimumMemberLevel[ ticketId ] > _memberLevel){   
            revert("Member level not sufficient enough for transfer.");
        }
        return; 
    }
    function expireable(uint256 ticketId) external view{
        LibERC1155TransferConstraints.ConstraintStorage storage cs = 
        LibERC1155TransferConstraints.erc1155ConstraintStorage();
        uint32 _expireTime = cs.expireTime[ ticketId ];
        require(block.timestamp > _expireTime, "Expired: Deadline for ticket consumption has passed.");
    }



   function constraintsEnforce(address from, address to, uint256 _tokenId) internal view {
    // Decode bitMap and nonce from tokenId
    uint128 bitMap = uint128(_tokenId >> 128);
    // uint192 nonce = uint192(_tokenId & type(uint192).max); // Not needed unless used elsewhere

    LibERC1155TransferConstraints.ConstraintStorage storage cs = 
        LibERC1155TransferConstraints.erc1155ConstraintStorage();

    // Check Transfer Limit (bit 0)
    if ((bitMap & (1 << 0)) != 0) {
        uint256 maxTransfers = cs.tranfserLimit[_tokenId]; // Fix typo: tranfserLimit → transferLimit
        nonTransferable(from, to, _tokenId); // Implement this 
    }
 
    // Check Minimum Membership Level (bit 1)
    if ((bitMap & (1 << 1)) != 0) {
        int64 minRank = cs.minimumMemberLevel[_tokenId];   
        int64 senderRank = _getMemberLevel( msgSender() ); // Implement this 
        require(senderRank >= minRank, "Insufficient membership level");
    }

    // Check Expiration Time (bit 2)
    if ((bitMap & (1 << 2)) != 0) {
        uint256 expireTime = cs.expireTime[_tokenId];
        require(block.timestamp < expireTime, "Token expired");
    }

   
}
/**
Would like to clean this function up at some point.
 */
    function ticketConstraintHandler(LibERC1155TransferConstraints.Constraints memory _constraints) internal returns (uint256){
        LibERC1155TransferConstraints.ConstraintStorage storage cs = LibERC1155TransferConstraints.erc1155ConstraintStorage();
        //check isActive to determine which ticketId interval it's in 
        uint128 bitMap; 
        uint128 nonce;
        uint128 incrementedNonce;
        uint256 ticketId;
        if(_constraints.transferLimit.isActive){
            //transferLimitConditions set
            bitMap ^= (1 << 1);
        }
        if(_constraints.minimumMembershipLevel.isActive){
            //memberRankDependency set
            bitMap ^= (1 << 2); 
        } 
        if(_constraints.expireable.isActive){ 
            //expireable set
            bitMap ^= (1 << 3);
        }
        if(_constraints.royaltyFee.isActive){ 
            //expireable set
            bitMap ^= (1 << 4);
        }
      
        
        //get nonce
        nonce = cs.ticketIntervalNonce[ bitMap ];  
        incrementedNonce = nonce + 1;
        
        //generate ticket id 
        ticketId = ( nonce ) +  bitMap * LibERC1155TransferConstraints.INTERVAL_SIZE;
         
       
        cs.ticketIntervalNonce[bitMap] = incrementedNonce;
        

        //store ticket constraints
        if(_constraints.transferLimit.isActive){
            cs.tranfserLimit[ticketId] = _constraints.transferLimit.maxTransfers;
        }
        if(_constraints.minimumMembershipLevel.isActive){ 
            cs.minimumMemberLevel[ticketId] = _constraints.minimumMembershipLevel.minimumLevel;
        }   
        if(_constraints.expireable.isActive){   
            cs.expireTime[ticketId] = _constraints.expireable.expireTime;
        } 
        if(_constraints.expireable.isActive){   
            cs.royaltyFee[ticketId] = _constraints.royaltyFee.fee;
        } 
        

        return ticketId;
    }

}

/**
 */