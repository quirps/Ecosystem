pragma solidity ^0.8.9;

import {LibERC1155TransferConstraints} from "../libraries/LibERC1155TransferConstraints.sol";
import { iOwnership } from "../../../Ownership/_Ownership.sol";
/**
 * @title 
 * @author 
 * @notice Future update will enable these constraints to have different addresess other than owner 
 */
contract  iTransferSetConstraints is iOwnership {
    error NonTransferableError(address from, address to, uint256 ticketId);
    //Transfer limit only applies to when from is non-zero and not creator and to is not the consumer address
    function nonTransferable( address from, address to) internal view returns (uint256){
        address _ecosystemOwner = _ecosystemOwner();
        if( from == address(0) || from == _ecosystemOwner ){
            return;
        }

        else if( to == _ecosystemOwner ){  
            return;
        }
        else{
            revert NonTransferableError(from, to, ticketId);  
        }
        
    }
    function minimumMembershipLevel(uint256 ticketId, address to) internal {
        //this will block the exchange from selling, so either give exchange membership level 
        //or make special exception for markets/exchanges that users can add
        //likely add the special clause to seperate concerns 
        //only issue is this will add a 2100 SLOAD each time, at a minimum on top of everything else.
        //could extend membership level to be a struct, including if it's an exchange
    }
    function setExpireable() external{
        LibERC1155TransferConstraints.ConstraintStorage storage cs = 
        LibERC1155TransferConstraints.erc1155ConstraintStorage();
        uint32 _expireTime = cs.expireTime[ ticketId ];
        require(block.timestamp > _expireTime, "Expired: Deadline for ticket consumption has passed.");
    }

   function constraintsEnforce(uint256 _tokenId) internal view {
    // Decode bitMap and nonce from tokenId
    uint128 bitMap = uint128(_tokenId >> 128);
    // uint192 nonce = uint192(_tokenId & type(uint192).max); // Not needed unless used elsewhere

    LibERC1155TransferConstraints.ConstraintStorage storage cs = 
        LibERC1155TransferConstraints.erc1155ConstraintStorage();

    // Check Transfer Limit (bit 0)
    if ((bitMap & (1 << 0)) != 0) {
        uint256 maxTransfers = cs.tranfserLimit[_tokenId]; // Fix typo: tranfserLimit → transferLimit
        uint256 currentTransfers = nonTransferable(_tokenId); // Implement this
        require(currentTransfers < maxTransfers, "Transfer limit exceeded");
    }

    // Check Minimum Membership Level (bit 1)
    if ((bitMap & (1 << 1)) != 0) {
        uint256 minRank = cs.minimumMemberRank[_tokenId];
        uint256 senderRank = getSenderRank(); // Implement this
        require(senderRank >= minRank, "Insufficient membership level");
    }

    // Check Expiration Time (bit 2)
    if ((bitMap & (1 << 2)) != 0) {
        uint256 expireTime = cs.expireTime[_tokenId];
        require(block.timestamp <= expireTime, "Token expired");
    }

    // Check Royalty Fee (bit 3)
    if ((bitMap & (1 << 3)) != 0) {
        uint256 royaltyFee = cs.royaltyFee[_tokenId];
        // Example: Enforce royalty payment during transfers
        enforceRoyaltyPayment(royaltyFee); // Implement this
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
            bitMap ^= (1 << 0);
        }
        if(_constraints.minimumMembershipLevel.isActive){
            //memberRankDependency set
            bitMap ^= (1 << 1); 
        } 
        if(_constraints.expireable.isActive){ 
            //expireable set
            bitMap ^= (1 << 2);
        }
        if(_constraints.royaltyFee.isActive){
            bitMap ^= (1 << 3);
        }
        
        //get nonce
        nonce = cs.ticketIntervalNonce[ bitMap ];
        incrementedNonce = nonce + 1;
        
        //generate ticket id 
        ticketId = ( nonce ) +  bitMap * LibERC1155TransferConstraints.INTERVAL_SIZE;
         
         //Skip over currency ticketId 0
         //INITIALIZATION REFACT SNIPPET
        if( ticketId == 0 ){
            ticketId++;
            incrementedNonce++;
        }
       
        cs.ticketIntervalNonce[bitMap] = incrementedNonce;
        

        //store ticket constraints
        if(_constraints.transferLimit.isActive){
            cs.tranfserLimit[ticketId] = _constraints.transferLimit.maxTransfers;
        }
        if(_constraints.minimumMembershipLevel.isActive){
            cs.minimumMemberRank[ticketId] = _constraints.minimumMembershipLevel.minimumRank;
        }
        if(_constraints.expireable.isActive){   
            cs.expireTime[ticketId] = _constraints.expireable.expireTime;
        } 
         if(_constraints.expireable.isActive){  
            cs.royaltyFee[ticketId] = _constraints.royaltyFee.percentage;
        }

        return ticketId;
    }

}

/**
 */