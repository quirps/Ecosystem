pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;


//


contract Members{
    mapping( address => MemberHistory[]) userMemberHistory;
    bytes32[] memberRoots;
    struct MemberHistory{
        uint96 timestamp;
        uint16 rank;
    }

    struct MerkleProof{
        bytes32 a;
    }

    // param takes in merkle proof
    // rejects on invalid prooof

    function _proveMembership(MerkleProof[] memory proof) internal view{
        // prove
    }
}