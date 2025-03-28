pragma solidity ^0.8.28;

import { LibERC2981 } from "./LibERC2981.sol";   
import { iOwnership } from "../Ownership/_Ownership.sol"; 
import { LibERC1155TransferConstraints } from "../Tokens/ERC1155/libraries/LibERC1155TransferConstraints.sol";
contract iERC2981 is iOwnership{
    event RoyaltyFeeAccessed( address sender, uint256 tokenId, uint256 salePrice, uint256 royaltyAmount);
      // EIP-2981 royalty info
    function _royaltyInfo(
        uint256 tokenId,
        uint256 salePrice
    ) internal  returns (address receiver, uint256 royaltyAmount) {
        LibERC1155TransferConstraints.ConstraintStorage storage cs = 
        LibERC1155TransferConstraints.erc1155ConstraintStorage();
        
        uint256 _royalteFee = cs.royaltyFee[ tokenId ];  
   
        receiver = _ecosystemOwner();
        royaltyAmount = ( salePrice * _royalteFee ) / 100000; // Basis points calculation
        
        emit RoyaltyFeeAccessed(msgSender(), tokenId, salePrice, royaltyAmount); 
    }
}