pragma solidity ^0.8.9;

import {iERC2771Recipient} from "../ERC2771Recipient/_ERC2771Recipient.sol";    
import "./ModeratorRankConstants.sol";
import "./LibModerator.sol"; 

contract ModeratorModifiers is ModeratorRankConstants, iERC2771Recipient {
    modifier moderatorMemberPermission(){
        require( LibModerator.getModeratorRank( msgSender() ) 
                 >= MODERATOR_MEMBER_PERMISSIONED ,"MS - Insufficient Priveleges.");
        _;
    }
}