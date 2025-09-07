// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./LibMemberLevel.sol";
// Importing OpenZeppelin's MerkleProof library for verification
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {iOwnership} from "../Ownership/_Ownership.sol";
/// @title MembershipLevelsInternal
/// @notice This contract contains the internal logic for the MembershipLevels facet.
/// Its functions are designed to be called by the external MembershipLevels facet contract.
contract iMembers is iOwnership {
    // --- Events ---

    /// @notice Emitted when a member's level is successfully updated.
    /// @param memberAddress The address of the member whose level was changed.
    /// @param newLevel The new numeric level ID.
    /// @param timestamp The timestamp associated with the level change.
    event MemberLevelUpdated(address indexed memberAddress, int64 newLevel, uint32 timestamp);

    /// @notice Emitted when the Merkle root is updated.
    /// @param newRoot The new Merkle root.
    event MerkleRootUpdated(bytes32 newRoot);

    /// @notice Emitted when a new level definition is added.
    /// @param _level The numeric ID of the new level.
    /// @param _name The name of the new level.
  
    event LevelDefinitionAdded(int64 _level, string  _name, string  _badge, string  _color);

    /// @notice Emitted when an existing level definition is updated.
    /// @param _level The numeric ID of the updated level.
    event LevelDefinitionUpdated(int64 _level, string  _name, string  _badge, string  _color);

    /// @notice Emitted when a level definition is marked as inactive.
    /// @param _level The numeric ID of the removed level.
    event LevelDefinitionRemoved(int64 _level);

    // --- End Events ---

    /// @notice Internal implementation for Merkle proof verification and setting a user's level.
    /// @dev This function computes the leaf hash and verifies it against the current Merkle root
    /// stored in `LibMemberLevel.memberLevelStorage().merkleRoot`.
    /// @param _leaf The leaf struct containing the member's address, desired level, and timestamp.
    /// @param _merkleProof The Merkle proof array.
    function _verifyAndSetLevel(LibMemberLevel.Leaf memory _leaf, bytes32[] calldata _merkleProof) internal {
        LibMemberLevel.MemberLevelStorage storage ms = LibMemberLevel.memberLevelStorage();

        // Calculate the hash of the leaf data
        // The order of encoding must match how the Merkle tree was built off-chain
        bytes32 leafHash = keccak256(abi.encodePacked(_leaf.memberAddress, _leaf.level, _leaf.timestamp));

        // Verify the Merkle proof against the current Merkle root
        require(MerkleProof.verify(_merkleProof, ms.merkleRoot, leafHash), "MembershipLevels: Invalid Merkle proof");

        // After successful verification, set the member's level using the timestamp provided in the leaf
        LibMemberLevel.permissionedChangeLevel(_leaf.level, _leaf.memberAddress, _leaf.timestamp);

        // Emit event for level update
        emit MemberLevelUpdated(_leaf.memberAddress, _leaf.level, _leaf.timestamp);
    }

    /// @notice Internal implementation to batch set levels for multiple addresses, each with its own Merkle proof.
    /// @dev This iterates through each leaf and its corresponding proof, calling `_verifyAndSetLevel` for each.
    /// Ensures that the number of leaves matches the number of proofs.
    /// @param _leaves An array of `Leaf` structs.
    /// @param _merkleProofs An array of Merkle proofs, corresponding to `_leaves`.
    function _batchSetLevels(LibMemberLevel.Leaf[] calldata _leaves, bytes32[][] calldata _merkleProofs) internal {
        require(_leaves.length == _merkleProofs.length, "MembershipLevels: Mismatch between leaves and proofs count");

        for (uint256 i = 0; i < _leaves.length; i++) {
            _verifyAndSetLevel(_leaves[i], _merkleProofs[i]);
        }
    }

    /// @notice Internal implementation to ban a member using a Merkle proof.
    /// @dev This function calls `_verifyAndSetLevel` with the provided banned leaf and its proof.
    /// It expects the `_bannedLeaf.level` to be the designated "banned" level (e.g., a specific negative `int64` ID).
    /// The actual banned level ID and its inclusion in the Merkle tree are handled off-chain.
    /// @param _bannedLeaf The Leaf struct for the user to be banned.
    /// @param _merkleProof The Merkle proof for `_bannedLeaf`.
    function _banMember(LibMemberLevel.Leaf memory _bannedLeaf, bytes32[] calldata _merkleProof) internal {
        // This function simply acts as a specialized wrapper around _verifyAndSetLevel.
        // The determination of what constitutes a "banned" level (e.g., level = -1)
        // is managed by the off-chain system that generates the Merkle tree and proofs.
        _verifyAndSetLevel(_bannedLeaf, _merkleProof);
    }

    /// @notice Internal implementation to get a user's `MemberLevel` struct.
    /// @param _user The address to query.
    function _getMemberLevelStruct(address _user) internal view returns (int64 level, uint32 timestamp) {
        LibMemberLevel.MemberLevelStorage storage ms = LibMemberLevel.memberLevelStorage();
        LibMemberLevel.MemberLevel memory memberLevel = ms.memberLevel[_user];
        return (memberLevel.level, memberLevel.timestamp);
    }

    /// @notice Internal implementation to get only a user's numeric level.
    /// @param _user The address to query.
    /// @return memberLevel_ numeric level of the user.
    function _getMemberLevel(address _user) internal view returns (int64 memberLevel_) {
        LibMemberLevel.MemberLevelStorage storage ms = LibMemberLevel.memberLevelStorage();
        return ms.memberLevel[_user].level;
    }

    // --- Internal implementations for Managing Level Definitions ---

    /// @notice Internal implementation to add a new level definition.
    /// @param _level The unique numeric ID for the level.
    /// @param _name The display name.
    /// @param _badge The badge URI.
    /// @param _color The hex color.
    function _addLevelDefinition(int64 _level, string memory _name, string memory _badge, string memory _color) internal {
        LibMemberLevel._addLevelDefinition(_level, _name, _badge, _color);
        emit LevelDefinitionAdded(_level, _name, _badge, _color);
    }

    /// @notice Internal implementation to update an existing level definition.
    /// @param _level The unique numeric ID of the level to update.
    /// @param _name The new display name.
    /// @param _badge The new badge URI.
    /// @param _color The new hex color.
    function _updateLevelDefinition(int64 _level, string memory _name, string memory _badge, string memory _color) internal {
        LibMemberLevel._updateLevelDefinition(_level, _name, _badge, _color);
        emit LevelDefinitionUpdated(_level, _name, _badge, _color);
    }

    /// @notice Internal implementation to remove (mark as inactive) a level definition.
    /// @param _level The unique numeric ID of the level to mark as inactive.
    function _removeLevelDefinition(int64 _level) internal {
        LibMemberLevel._removeLevelDefinition(_level);
        emit LevelDefinitionRemoved(_level);
    }

    /// @notice Internal implementation to get a specific level definition.
    /// @param _level The numeric ID of the level to retrieve.
    /// @return levelDefinition `LibMemberLevel.LevelDefinition` struct.
    function _getLevelDefinition(int64 _level) internal view returns (LibMemberLevel.LevelDefinition memory levelDefinition) {
        return LibMemberLevel._getLevelDefinition(_level);
    }

    /// @notice Internal implementation to get all active level definitions.
    /// @return levelDefinitions array of `LibMemberLevel.LevelDefinition` structs.
    function _getAllLevelDefinitions() internal view returns (LibMemberLevel.LevelDefinition[] memory levelDefinitions) {
        return LibMemberLevel._getAllLevelDefinitions();
    }

    /// @notice Internal implementation to get names of all active level definitions.
    /// @return levelNames array of strings.
    function _getLevelNames() internal view returns (string[] memory levelNames) {
        LibMemberLevel.MemberLevelStorage storage ms = LibMemberLevel.memberLevelStorage();
        uint256 activeCount = 0;
        // Count active definitions
        for (uint256 i = 0; i < ms.allLevelIds.length; i++) {
            if (ms.levelDefinitions[ms.allLevelIds[i]].exists) {
                activeCount++;
            }
        }
        string[] memory names = new string[](activeCount);
        uint256 currentIdx = 0;
        // Populate names array
        for (uint256 i = 0; i < ms.allLevelIds.length; i++) {
            int64 levelId = ms.allLevelIds[i];
            if (ms.levelDefinitions[levelId].exists) {
                names[currentIdx] = ms.levelDefinitions[levelId].name;
                currentIdx++;
            }
        }
        return names;
    }

    /// @notice Internal implementation to update the Merkle root.
    /// @param _newRoot The new 32-byte Merkle root hash.
    function _setMerkleRoot(bytes32 _newRoot) internal {
        LibMemberLevel._setMerkleRoot(_newRoot);
        emit MerkleRootUpdated(_newRoot);
    }
}