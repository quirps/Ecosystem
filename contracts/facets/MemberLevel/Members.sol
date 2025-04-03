// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18; // Use a recent stable version

// --- Interfaces ---
// Assuming IMembers defines the external functions for this facet
// import { IMembers } from "./IMembers.sol";

// --- Libraries ---
// Needed for Leaf struct definition used in batchSetLevels
import { LibMemberLevel } from "./LibMemberLevel.sol"; 
// --- Implementation Contracts ---
import { iMembers } from "./_Members.sol"; // Import the internal logic

/// @title Members Facet External Interface
/// @notice Provides external functions to manage and view member levels using int64.
/// Handles access control and forwards calls to internal logic.
contract Members is /* IMembers, */ iMembers { // Implement interface, Inherit internal logic

    // --- Owner Functions ---

    /// @notice EXTERNAL: Updates the Merkle root for level proofs. Owner only.
    /// @param _merkleRoot New Merkle root hash.
    function updateMemberMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        _updateMemberMerkleRoot(_merkleRoot);
    }

    /// @notice EXTERNAL: Batch sets levels for multiple members. Owner only.
    /// @dev Uses Leaf struct containing address, level (int64), and timestamp.
    /// @param _leaves Array of member level data.
    function batchSetLevels(LibMemberLevel.Leaf[] calldata _leaves) external onlyOwner {
        _batchSetLevels(_leaves);
    }

    /// @notice EXTERNAL: Directly sets the level for a single member. Owner only.
    /// @dev Requires the new timestamp implicit in the call (block.timestamp) to be newer than the existing one.
    /// @param user Address of the member.
    /// @param level The new level (int64, can be negative e.g., BANNED_LEVEL).
    function setMemberLevel(address user, int64 level) external onlyOwner {
        _setMemberLevel(user, level);
    }

    /// @notice EXTERNAL: Bans a member by setting their level to BANNED_LEVEL (-1). Owner only.
    /// @param _user Address of the user to ban.
    function banMember(address _user) external onlyOwner {
        _banMember(_user);
    }

    // --- User Functions ---

    /// @notice EXTERNAL: Allows a user to claim their level using a Merkle proof.
    /// @dev Proof must be valid against the current root and match msg.sender, level, and timestamp.
    /// Consider internal timestamp check if strict ordering/replay prevention is needed beyond proof validation.
    /// @param level The level (int64) being claimed.
    /// @param timestamp The timestamp associated with the claim (must match proof).
    /// @param _merkleProof Array of hashes for Merkle verification.
    function verifyAndSetLevel(int64 level, uint32 timestamp, bytes32[] calldata _merkleProof) external {
        _verifyAndSetLevel(level, timestamp, _merkleProof);
    }

    // --- View Functions ---

    /// @notice Gets the full level struct (level and timestamp) for a given address.
    /// @param _user Address to query.
    /// @return struct containing level (int64) and timestamp (uint32).
    function getMemberLevelStruct(address _user) external view returns (LibMemberLevel.MemberLevel memory) {
        return _getMemberLevelStruct(_user);
    }

    /// @notice Gets just the level (int64) for a given address.
    /// @dev Level can be positive, zero, or negative (e.g., BANNED_LEVEL).
    /// @param _user Address to query.
    /// @return int64 The user's current level.
    function getMemberLevel(address _user) external view returns (int64) {
        return _getMemberLevel(_user);
    }

    /// @notice Gets just the timestamp for the last level update of a given address.
    /// @param _user Address to query.
    /// @return uint32 The Unix timestamp of the last level update.
    function getMemberLevelTimestamp(address _user) external view returns (uint32) {
        return _getMemberLevelTimestamp(_user);
    }

     /// @notice Gets the currently active Merkle root being used for level proofs.
     /// @return bytes32 The current Merkle root hash.
    function getMerkleRoot() external view returns (bytes32) {
        // Access storage via the library function inherited implicitly
        LibMemberLevel.MemberLevelStorage storage mrs = LibMemberLevel.memberLevelStorage();
        return mrs.merkleRoot;
    }

    /// @notice Gets the defined constant value representing a banned level.
    /// @return int64 The value indicating a ban (e.g., -1).
    function getBannedLevel() external pure returns (int64) {
        // Access constant defined in inherited iMembers
        return BANNED_LEVEL;
    }

    // --- Cleanup Legacy/Unused Imports (Review Manually) ---
    // Remove `import "../Tokens/ERC1155/ERC1155Transfer.sol";` if unused.
    // Remove `import "./_Members.sol";` (replaced by iMembers).
    // Remove `import "../../libraries/merkleVerify/MembersVerify.sol";` (Merkle logic now internal).
    // Ensure `import "./IMembers.sol";` is correct if using the interface.
}