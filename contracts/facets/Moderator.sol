pragma solidity ^0.8.9;

/**
 * Moderators take on a heightened role in ecosystems and are responsible
 * for various priveleged duties. Moderator roles are assigned to a value
 * in a well ordered set, where higher ranks contain the more priveleges and
 * subsume lower ranks priveleges. 
 * 
 * Same system as member rank is used, RankLabel mapped to well ordered set.
 */

contract Moderator{
    struct ModeratorRank{
    
    }

    modifier moderator (){
        //moderator of rank index n-1 or lower reject
        _;
    }
    mapping( address => bytes30 ) moderatorRankLabel;
    mapping( bytes30 => uint8 ) moderatorRank
    bytes30[] rankLabels;

    function setModeratorRank(address newModerator, bytes30 rankLabel) external {
        moderatorRankLabel[ newModerator ] = rankLabel;
    }
    function getModeratorRank(address moderator) external returns(address moderatorRank_){
        bytes30 moderatorRankLabel = moderatorRankLabel[ moderator ];
        moderatorRank_ = moderatorRank[ moderatorRankLabel ];
    }
    
}