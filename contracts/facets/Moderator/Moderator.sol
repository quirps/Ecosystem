pragma solidity ^0.8.6;

/**
 * Moderators take on a heightened role in ecosystems and are responsible
 * for various priveleged duties. Moderator roles are assigned to a value
 * in a well ordered set, where higher ranks contain the more priveleges and
 * subsume lower ranks priveleges. 
 * 
 * Same system as member rank is used, RankLabel mapped to well ordered set.
 */
import "../libraries/LibModerator.sol";
contract Moderator {
    /**
     * Just create a ranked list, address associated with number.
     * Moderators should only need to be referencable via current ecosystem, 
     * or directly called by other ecosystems. 
     */
 

    //only owner
    function setModeratorRank(address _moderator, uint8 _rank) external {
        LibModerator.setModeratorRank(_moderator, _rank);
    }
    function getModeratorRank(address _moderator) external view returns(uint8 moderatorRank_){
        moderatorRank_ = LibModerator.getModeratorRank( _moderator );
    }
    
}