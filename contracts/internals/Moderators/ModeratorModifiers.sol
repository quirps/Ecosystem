pragma solidity ^0.8.9;

import "./ModeratorRankConstants.sol";
import "../../libraries/utils/Context.sol";
import "../../libraries/LibModerator.sol";

contract ModeratorModifiers is ModeratorRankConstants, Context{
    modifier moderatorMemberPermission(){
        require( LibModerator.getModeratorRank( msgSender() ) 
                 >= MODERATOR_MEMBER_PERMISSIONED ,"MS - Insufficient Priveleges.");
        _;
    }
}