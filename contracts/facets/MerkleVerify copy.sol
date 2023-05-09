pragma solidity ^0.8.6;
import "../libraries/utils/MerkleProof.sol";

contract Verifier {
    bytes32 private root;

    constructor(bytes32 _root) {
        // (1)
        root = _root;
    }

    struct Account {
        address addr;
        uint256 amount;
    }

    function verify(
        bytes32[] memory proof,
        address addr,
        uint256 amount
    ) public {
        // (2)
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(addr, amount))));
        // (3)
        require(MerkleProof.verify(proof, root, leaf), "Invalid proof");
        // (4)
        // ...
    }

    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        Account[] memory leaves )
            external view {
        
        bytes32[] memory hashedLeaves = new bytes32[](leaves.length);
        for( uint32 i; i < leaves.length; i++){
            bytes32 hashedLeaf = keccak256(bytes.concat(keccak256(abi.encode(leaves[i].addr, leaves[i].amount))));
            hashedLeaves[i] = hashedLeaf;
        }
        // (2)
        //bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(addr, amount))));
        // (3)
        require(MerkleProof.multiProofVerify( proof, proofFlags, root, hashedLeaves ),"Invalid Multiproof" );
        // (4)
        // ...
    }
}