pragma solidity ^0.8.6;

library LibModerator{
    bytes32 constant MODERATOR_STORAGE_POSITION = keccak256("diamond.standard.Moderator.storage");
    struct Moderator_Storage{
        mapping( address => uint8 ) moderatorRank;
    }

    function moderatorStorage() internal pure returns (Moderator_Storage storage es){
        bytes32 Moderator_STORAGE_POSITION = MODERATOR_STORAGE_POSITION;
        assembly{
            es.slot := Moderator_STORAGE_POSITION
        }
    }

    function setModeratorRank(address _moderator, uint8 rank) internal {
        moderatorStorage().moderatorRank[ _moderator ] = rank;
    }
    function getModeratorRank(address _moderator) internal view returns (uint8 rank_) {
        rank_ = moderatorStorage().moderatorRank[ _moderator ];
    }
}