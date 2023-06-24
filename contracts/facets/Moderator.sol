pragma solidity ^0.8.6;

/**
 * Moderators take on a heightened role in ecosystems and are responsible
 * for various priveleged duties. Moderator roles are assigned to a value
 * in a well ordered set, where higher ranks contain the more priveleges and
 * subsume lower ranks priveleges. 
 * 
 * Same system as member rank is used, RankLabel mapped to well ordered set.
 */

contract Moderator{
    /**
     * Just create a ranked list, address associated with number.
     * Moderators should only need to be referencable via current ecosystem, 
     * or directly called by other ecosystems. 
     */
    modifier moderator (){
        //moderator of rank index n-1 or lower reject
        _;
    }
    mapping( address => uint8 ) moderatorRank;


    function setModeratorRank(address newModerator, uint8 _rank) external {
        moderatorRank[ newModerator ] = _rank;
    }
    function getModeratorRank(address _moderator) external returns(uint8 moderatorRank_){
        moderatorRank_ = moderatorRank[ _moderator ];
    }
    
}