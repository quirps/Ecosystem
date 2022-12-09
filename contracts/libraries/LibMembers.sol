pragma solidity ^0.8.6;

library Members{
    bytes32 constant MEMBER_STORAGE_POSITION = keccak256("diamond.standard.members.storage");
    struct Roles{
        mapping(address => uint16) userTier;
    }

    function memberStorage() internal pure returns (Roles storage rs_ ){
        bytes32 position = MEMBER_STORAGE_POSITION;
        assembly{
            rs_.slot := position
        }
    }
}