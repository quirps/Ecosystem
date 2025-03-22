pragma solidity ^0.8.9;
 
   
import "./LibMemberLevel.sol";  
import "../../libraries/utils/Incrementer.sol"; 
import "../Moderator/LibModerator.sol";  
import "../Moderator/ModeratorModifiers.sol";   
import {iOwnership} from "../Ownership/_Ownership.sol"; 
import { LibMemberLevel} from "./LibMemberLevel.sol"; 
  
contract iMembers is iOwnership {   
    event MerkleRootUpdated(bytes32 newRoot);
    event MemberLevelUpdated(LibMemberLevel.Leaf leaf);
    event MemberBanned(address indexed user, uint32 timestamp); 
      /**  
     * @dev Updates the Merkle root
     * @param _merkleRoot New Merkle root to be stored
     */
     function updateMemberMerkleRoot(bytes32 _merkleRoot) internal  {
        isEcosystemOwnerVerification();
        LibMemberLevel.MemberLevelStorage storage mrs = LibMemberLevel.memberLevelStorage();
        mrs.merkleRoot = _merkleRoot; 
        emit MerkleRootUpdated(_merkleRoot);
    }
        /**
     * @dev Verifies Merkle proof and sets user's level
     * @param _leaf Level to assign to the user
     * @param _merkleProof Array of hashed data to verify proof
     */ 
    function _verifyAndSetLevel(LibMemberLevel.Leaf memory _leaf, bytes32[] calldata _merkleProof) internal {
        // Create leaf from msg.sender and level
        LibMemberLevel.MemberLevelStorage storage mrs = LibMemberLevel.memberLevelStorage();

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, _leaf.level, _leaf.timestamp));
        
        require(_verifyMerkleProof(_merkleProof, mrs.merkleRoot, leaf), "Invalid Merkle proof");
          
        // Set the member level
        mrs.memberLevel[msg.sender] = LibMemberLevel.MemberLevel({
            level: _leaf.level,
            timestamp: _leaf.timestamp
        });
        
        emit MemberLevelUpdated(_leaf);  
    }

       /**
     * @dev Helper function to verify Merkle proofs
     */
    function _verifyMerkleProof(bytes32[] calldata proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;
        
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        
        // Check if the computed hash equals the root of the Merkle tree
        return computedHash == root;
    }
    
    /**
     * @dev Batch set levels for multiple addresses (permissioned function)
     * @param _leaves user resource denoting their membership status
     *   
     */
    function _batchSetLevels( LibMemberLevel.Leaf[] calldata _leaves) internal {
        isEcosystemOwnerVerification();
        LibMemberLevel.MemberLevelStorage storage mrs = LibMemberLevel.memberLevelStorage();
        
        for (uint256 i = 0; i < _leaves.length; i++) {
            LibMemberLevel.Leaf memory _leaf = _leaves[ i ]; 
            mrs.memberLevel[ _leaf.memberAddress ] = LibMemberLevel.MemberLevel({
                level: _leaf.level,
                timestamp: _leaf.timestamp
            });
            
            emit MemberLevelUpdated(_leaf);    
        }
    }

     /**
     * @dev Returns the level info for a given address
     * @param _user Address to query
     * @return level and timestamp of the user
     */
    function _getMemberLevelStruct(address _user) internal view returns (uint32 level, uint32 timestamp) {
        LibMemberLevel.MemberLevelStorage storage mrs = LibMemberLevel.memberLevelStorage();
        LibMemberLevel.MemberLevel storage memberLevelStruct = mrs.memberLevel[ _user ];
        return (memberLevelStruct.level, memberLevelStruct.timestamp);
    }

    /**
     * @dev Returns the level info for a given address
     * @param _user Address to query 
     */
    function _getMemberLevel(address _user) internal view returns (uint32 memberLevel_) {
        LibMemberLevel.MemberLevelStorage storage mrs = LibMemberLevel.memberLevelStorage();
        memberLevel_ = mrs.memberLevel[ _user ].level;  
    }
    

    /**
     * @dev Bans a user by setting their level to 0
     * @param _user Address of the user to ban
     */
    function _banMember(address _user) internal onlyOwner {
        LibMemberLevel.MemberLevelStorage storage mrs = LibMemberLevel.memberLevelStorage();
        uint32 currentTimestamp = uint32(block.timestamp);
        
        mrs.memberLevel[_user] = LibMemberLevel.MemberLevel({
            level: 0,
            timestamp: currentTimestamp
        });
        
        emit MemberBanned(_user, currentTimestamp);
    }
}

