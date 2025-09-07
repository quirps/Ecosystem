// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2; // Required for structs in calldata/return data with complex types

import "./LibMemberLevel.sol";

interface IMembers {

    /// @dev Verifies a Merkle proof against the current Merkle root and sets a user's level based on the leaf data.
    /// The `_leaf.timestamp` will be recorded on-chain.
    /// @param _leaf A struct containing the member's address, desired level, and timestamp.
    /// @param _merkleProof An array of hashed data required to verify the proof.
    function verifyAndSetLevel(LibMemberLevel.Leaf memory _leaf, bytes32[] calldata _merkleProof) external;

    /// @dev Sets levels for multiple addresses in a single transaction, with individual Merkle proofs for each.
    /// Each `_leaf.timestamp` will be recorded on-chain.
    /// @param _leaves An array of `Leaf` structs, each containing the member's address, level, and timestamp.
    /// @param _merkleProofs An array of Merkle proofs, where each proof corresponds to a leaf in `_leaves`.
    function batchSetLevels(LibMemberLevel.Leaf[] calldata _leaves, bytes32[][] calldata _merkleProofs) external;

    /// @dev Sets a user's level to a designated "banned" level, requiring a Merkle proof.
    /// The `_bannedLeaf` must contain the target user's address, the "banned" level ID, and a timestamp.
    /// This timestamp will be recorded on-chain.
    /// @param _bannedLeaf The Leaf struct for the user to be banned, including the specific banned level ID.
    /// @param _merkleProof The Merkle proof for `_bannedLeaf`.
    function banMember(LibMemberLevel.Leaf memory _bannedLeaf, bytes32[] calldata _merkleProof) external;

    /// @dev Returns a struct containing the current level and the timestamp of assignment for a given address.
    /// @param _user The address to query.
    /// @return level The member's assigned numeric level (int64).
    /// @return timestamp The Unix timestamp when the level was assigned (uint32).
    function getMemberLevelStruct(address _user) external view returns (int64 level, uint32 timestamp);

    /// @dev Returns only the numeric level for a given address.
    /// @param _user The address to query.
    /// @return memberLevel_ The numeric level of the user (int64).
    function getMemberLevel(address _user) external view returns (int64 memberLevel_);

    // --- Functions for Managing Member Level Definitions (admin functions) ---

    /// @dev Adds a new definition for a member level, including its name, badge, and color.
    /// This function is typically restricted to administrators/owners.
    /// @param _level The unique numeric ID for the level.
    /// @param _name The display name of the member level.
    /// @param _badge The URI to the badge icon.
    /// @param _color The hex color code.
    function addLevelDefinition(int64 _level, string calldata _name, string calldata _badge, string calldata _color) external;

    /// @dev Updates the name, badge, and color for an existing member level definition.
    /// This function is typically restricted to administrators/owners.
    /// @param _level The unique numeric ID of the level to update.
    /// @param _name The new display name.
    /// @param _badge The new badge URI.
    /// @param _color The new hex color code.
    function updateLevelDefinition(int64 _level, string calldata _name, string calldata _badge, string calldata _color) external;

    /// @dev Marks an existing member level definition as inactive.
    /// This function is typically restricted to administrators/owners.
    /// @param _level The unique numeric ID of the level to mark as inactive.
    function removeLevelDefinition(int64 _level) external;

    /// @dev Retrieves the full definition of a specific member level by its ID.
    /// @param _level The numeric ID of the level to retrieve.
    /// @return levelDefinition A `LibMemberLevel.LevelDefinition` struct.
    function getLevelDefinition(int64 _level) external view returns (LibMemberLevel.LevelDefinition memory levelDefinition);

    /// @dev Retrieves an array of all currently active member level definitions.
    /// @return levelDefinitions An array of `LibMemberLevel.LevelDefinition` structs.
    function getAllLevelDefinitions() external view returns (LibMemberLevel.LevelDefinition[] memory levelDefinitions);

    /// @dev Retrieves an array containing only the names of all currently active member levels.
    /// @return levelNames An array of strings.
    function getLevelNames() external view returns (string[] memory levelNames);

    /// @dev Updates the Merkle root against which all level updates are verified.
    /// This is a highly permissioned function, typically called by a trusted off-chain process
    /// after generating a new Merkle tree state.
    /// @param _newRoot The new 32-byte Merkle root hash.
    function setMerkleRoot(bytes32 _newRoot) external;
}