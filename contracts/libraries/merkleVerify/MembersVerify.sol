pragma solidity ^0.8.6;

import "../utils/MerkleProof.sol";
import "../LibMembers.sol";


library MembersVerify {

    function verify(bytes32[] memory proof, address addr, uint256 amount) public view{
        LibMembers.MembersStorage storage ms = LibMembers.memberStorage();
        bytes32 root = ms.MembersMerkleRoot;
        // (2)
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(addr, amount))));
        // (3)
        require(MerkleProof.verify(proof, root, leaf), "Invalid proof");
        // (4)
        // ...
    }

    function multiProofVerify(bytes32[] memory proof, bool[] memory proofFlags, LibMembers.MerkleLeaf[] memory leaves) internal view {
        LibMembers.MembersStorage storage ms = LibMembers.memberStorage();
        bytes32 root = ms.MembersMerkleRoot;
        bytes32[] memory hashedLeaves = new bytes32[](leaves.length);
        for (uint32 i; i < leaves.length; i++) {
            bytes32 hashedLeaf = keccak256(
                bytes.concat(keccak256(abi.encode(leaves[i].memberAddress, leaves[i].memberRank.timestamp, leaves[i].memberRank.rank)))
            );
            hashedLeaves[i] = hashedLeaf;
        }
        // (2)
        //bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(addr, amount))));
        // (3)
        require(MerkleProof.multiProofVerify(proof, proofFlags, root, hashedLeaves), "Invalid Multiproof");
        // (4)
        // ...
    }
}
