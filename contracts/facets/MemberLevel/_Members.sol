// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18; // Use a recent stable version

// --- Libraries ---
// Assuming LibMemberLevel defines:
// struct MemberLevel { int64 level; uint32 timestamp; }
// struct Leaf { address memberAddress; int64 level; uint32 timestamp; }
// struct MemberLevelStorage { bytes32 merkleRoot; mapping(address => MemberLevel) memberLevel; }
// function memberLevelStorage() internal pure returns (MemberLevelStorage storage mrs);
import { LibMemberLevel } from "./LibMemberLevel.sol";

// --- Base Contracts ---
import { iOwnership } from "../Ownership/_Ownership.sol"; // Assumed for onlyOwner

/// @title iMembers Internal Logic Contract
/// @notice Handles internal logic for member level management, including Merkle proofs,
/// direct setting by owner, banning, and level retrieval. Uses int64 for levels.
contract iMembers is iOwnership {

    /// @notice Represents the level assigned to banned members.
    int64 internal constant BANNED_LEVEL = type(int64).min;  

    // --- Events ---

    /// @notice Emitted when the owner updates the Merkle root for level proofs.
    /// @param newRoot The new Merkle root hash.
    event MerkleRootUpdated(bytes32 newRoot);

    /// @notice Emitted when a member's level is updated via proof, direct set, or batch set.
    /// @param user The address of the member whose level was updated.
    /// @param level The new level assigned (can be negative, e.g., BANNED_LEVEL).
    /// @param timestamp The timestamp associated with this level update.
    event MemberLevelUpdated(address indexed user, int64 level, uint32 timestamp);

    /// @notice Emitted when a member is banned by the owner.
    /// @param user The address of the banned member.
    /// @param timestamp The timestamp when the ban occurred.
    event MemberBanned(address indexed user, uint32 timestamp);

    // --- Owner Functions (Internal Logic) ---

    /// @dev Updates the Merkle root used for verifying level proofs. Owner only.
    /// @param _merkleRoot New Merkle root to be stored.
    function _updateMemberMerkleRoot(bytes32 _merkleRoot) internal onlyOwner {
        LibMemberLevel.MemberLevelStorage storage mrs = LibMemberLevel.memberLevelStorage();
        mrs.merkleRoot = _merkleRoot;
        emit MerkleRootUpdated(_merkleRoot);
    }

    /// @dev Batch sets levels for multiple addresses. Owner only.
    /// @param _leaves Array containing address, level, and timestamp for each member.
    function _batchSetLevels(LibMemberLevel.Leaf[] calldata _leaves) internal onlyOwner {
        LibMemberLevel.MemberLevelStorage storage mrs = LibMemberLevel.memberLevelStorage();
        uint256 leavesLen = _leaves.length;
        for (uint256 i = 0; i < leavesLen; ) {
            LibMemberLevel.Leaf calldata leaf = _leaves[i]; // Use calldata reference

            // Consider adding timestamp check if needed:
            // require(leaf.timestamp > mrs.memberLevel[leaf.memberAddress].timestamp, "Timestamp must be newer");

            mrs.memberLevel[leaf.memberAddress] = LibMemberLevel.MemberLevel({
                level: leaf.level,
                timestamp: leaf.timestamp
            }); 

            emit MemberLevelUpdated(leaf.memberAddress, leaf.level, leaf.timestamp);

            // Use unchecked arithmetic for safe loop increment
            unchecked { ++i; }
        }
    }

    /// @dev Directly sets the level for a single user. Requires timestamp check.
    /// @notice Access control (Owner/Moderator) should be applied in the calling external function.
    /// @param user Address of the member.
    /// @param level The new level to assign (can be negative).
    function _setMemberLevel(address user, int64 level) internal {
        LibMemberLevel.MemberLevelStorage storage mrs = LibMemberLevel.memberLevelStorage();
        uint32 currentLevelTimestamp = mrs.memberLevel[user].timestamp;
        uint32 newTimestamp = uint32(block.timestamp); // Safe cast for realistic timestamps

        // Prevent setting level with a timestamp older than or equal to the current one
        require(newTimestamp > currentLevelTimestamp, "Timestamp must be newer");

        mrs.memberLevel[user] = LibMemberLevel.MemberLevel({
            level: level,
            timestamp: newTimestamp
        });

        emit MemberLevelUpdated(user, level, newTimestamp);
    }

    /// @dev Bans a user by setting their level to BANNED_LEVEL. Owner only.
    /// @param _user Address of the user to ban.
    function _banMember(address _user) internal onlyOwner {
        LibMemberLevel.MemberLevelStorage storage mrs = LibMemberLevel.memberLevelStorage();
        uint32 currentTimestamp = uint32(block.timestamp); // Safe cast

        // No timestamp check needed for ban, owner action overrides.
        mrs.memberLevel[_user] = LibMemberLevel.MemberLevel({
            level: BANNED_LEVEL,
            timestamp: currentTimestamp
        });

        emit MemberBanned(_user, currentTimestamp);
        // Optional: Emit MemberLevelUpdated as well if downstream systems rely on it
        // emit MemberLevelUpdated(_user, BANNED_LEVEL, currentTimestamp);
    }

    // --- User Claim Function (Internal Logic) ---

    /// @dev Verifies Merkle proof submitted by user (`msg.sender`) and sets their level.
    /// @param level Level being claimed by the user.
    /// @param timestamp Timestamp associated with the level claim (used in proof).
    /// @param _merkleProof Array of hashes to verify proof against the current root.
    function _verifyAndSetLevel(int64 level, uint32 timestamp, bytes32[] calldata _merkleProof) internal {
        LibMemberLevel.MemberLevelStorage storage mrs = LibMemberLevel.memberLevelStorage();

        // Consider adding timestamp check if needed:
        // require(timestamp > mrs.memberLevel[msg.sender].timestamp, "Timestamp must be newer");

        // Hash includes msg.sender, ensuring proof is for the caller
        bytes32 leafHash = keccak256(abi.encodePacked(msg.sender, level, timestamp));

        require(_verifyMerkleProof(_merkleProof, mrs.merkleRoot, leafHash), "Invalid Merkle proof");

        // Set the member level
        mrs.memberLevel[msg.sender] = LibMemberLevel.MemberLevel({
            level: level,
            timestamp: timestamp // Use timestamp from proof
        });

        emit MemberLevelUpdated(msg.sender, level, timestamp);
    }

    // --- View Functions (Internal Logic) ---

    /// @dev Returns the level struct (level and timestamp) for a given address.
    function _getMemberLevelStruct(address _user) internal view returns (LibMemberLevel.MemberLevel memory) {
        LibMemberLevel.MemberLevelStorage storage mrs = LibMemberLevel.memberLevelStorage();
        return mrs.memberLevel[_user]; // Returns struct (level can be negative)
    }

    /// @dev Returns just the level for a given address.
    function _getMemberLevel(address _user) internal view returns (int64) {
        LibMemberLevel.MemberLevelStorage storage mrs = LibMemberLevel.memberLevelStorage();
        return mrs.memberLevel[_user].level; // Returns level (can be negative)
    }

    /// @dev Returns just the timestamp for a given address's current level.
    function _getMemberLevelTimestamp(address _user) internal view returns (uint32) {
        LibMemberLevel.MemberLevelStorage storage mrs = LibMemberLevel.memberLevelStorage();
        return mrs.memberLevel[_user].timestamp;
    }

    // --- Helper Functions ---

    /// @dev Helper function to verify Merkle proofs. Standard implementation.
    function _verifyMerkleProof(bytes32[] calldata proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;
        uint256 proofLen = proof.length;
        for (uint256 i = 0; i < proofLen; ) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
            // Use unchecked arithmetic for safe loop increment
            unchecked { ++i; }
        }
        return computedHash == root;
    }
}