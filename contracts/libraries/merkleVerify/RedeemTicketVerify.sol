pragma solidity ^0.8.6;

import "../utils/MerkleProof.sol";



library RedeemTicketVerify {

    struct Leaf{
        address userAddress;
        address successor;
    }

    function verify(bytes32[] memory proof, bytes32 leaf , bytes32 root) internal pure{
        require(MerkleProof.verify(proof, root, leaf), "Invalid proof");
    }

    
}
