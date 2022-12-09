pragma solidity ^0.8.6;

import {MerkleProof} from "../libraries/Utils/MerkleProof.sol";

//User Verify 
/// @title Enable users to verify themselves within your ecosystem
/// @author Quirp
/// @notice Verify a user from your channel, thereby associating an 
///         address with a username.
/// @dev Creator will have a publicly available merkle tree, 
///       where the leaf hash is:
///      keccack256({username} + {address} + {ranking}).     
///      '+' symbol denotes concatenation of string variables
///      
///      User who wants to verify will simply execute the UserVerify
///      method. 

contract UserVerify{

    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) external pure returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

}