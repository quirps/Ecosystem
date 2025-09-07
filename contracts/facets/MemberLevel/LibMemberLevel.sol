// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

library LibMemberLevel {
    // Unique storage position for the MembershipLevels data in a Diamond
    bytes32 constant MEMBER_STORAGE_POSITION = keccak256("diamond.standard.members.storage");

    // Struct to define the properties of a membership level
    struct LevelDefinition {
        int64 level;  // Unique numeric ID for the level (can be negative)
        string name;  // Display name of the level (e.g., "Bronze", "VIP")
        string badge; // URI to an image representing the badge for this level
        string color; // Hex color code associated with this level
        bool exists;  // Flag to indicate if this level definition is active
    }

    // Struct to store a member's current level and when it was assigned
    struct MemberLevel {
        int64 level;     // The numeric level of the member
        uint32 timestamp; // Unix timestamp when this level was assigned
    }

    // Struct representing a Merkle tree leaf for member level updates
    // This is the data that will be hashed and verified by a Merkle proof
    struct Leaf {
        address memberAddress; // The address of the member to update
        int64 level;           // The target level for the member
        uint32 timestamp;      // The timestamp of this specific update
    }

    // Main storage struct for all MembershipLevels data
    struct MemberLevelStorage {
        mapping(address => MemberLevel) memberLevel;     // Stores each member's current level and timestamp
        mapping(int64 => LevelDefinition) levelDefinitions; // Stores definitions for each possible level ID
        int64[] allLevelIds;                             // A dynamic array to keep track of all level IDs ever added (even inactive)
        bytes32 merkleRoot;                              // The current Merkle root for level verification
    }

    /// @notice Returns a reference to the singleton `MemberLevelStorage` struct.
    /// @dev This uses EIP-2535 Diamond storage pattern.
    function memberLevelStorage() internal pure returns (MemberLevelStorage storage ms_) {
        bytes32 position = MEMBER_STORAGE_POSITION;
        assembly {
            ms_.slot := position
        }
    }

    /// @notice Internal function to set a member's level and timestamp.
    /// @dev This function is called *after* successful Merkle proof verification.
    /// It updates the member's record in storage.
    /// @param _level The numeric level to assign.
    /// @param _member The address of the member whose level is being updated.
    /// @param _timestamp The timestamp associated with this level update (from the Merkle Leaf).
    function permissionedChangeLevel(int64 _level, address _member, uint32 _timestamp) internal {
        MemberLevelStorage storage ms = memberLevelStorage();
        // Ensure that the level being set has a corresponding active definition
        require(ms.levelDefinitions[_level].exists, "LibMemberLevel: Level definition does not exist");
        ms.memberLevel[_member] = MemberLevel(_level, _timestamp); // Use the provided timestamp from the leaf
    }

    /// @notice Internal function to update the global Merkle root.
    /// @dev This root is used for verifying all member level update proofs.
    /// @param _newRoot The new 32-byte Merkle root hash.
    function _setMerkleRoot(bytes32 _newRoot) internal {
        MemberLevelStorage storage ms = memberLevelStorage();
        ms.merkleRoot = _newRoot;
    }

    // --- Internal functions for managing Level Definitions ---

    /// @notice Internal function to add a new level definition to storage.
    /// @dev Requires that the `_level` ID does not already exist.
    /// @param _level The unique numeric ID for the level.
    /// @param _name The display name of the member level.
    /// @param _badge The URI to the badge icon.
    /// @param _color The hex color code.
    function _addLevelDefinition(int64 _level, string memory _name, string memory _badge, string memory _color) internal {
        MemberLevelStorage storage ms = memberLevelStorage();
        require(!ms.levelDefinitions[_level].exists, "LibMemberLevel: Level ID already exists");
        ms.levelDefinitions[_level] = LevelDefinition(_level, _name, _badge, _color, true);
        ms.allLevelIds.push(_level); // Add to the list of all defined IDs
    }

    /// @notice Internal function to update an existing level definition in storage.
    /// @dev Requires that the `_level` ID already exists and is active.
    /// @param _level The unique numeric ID of the level to update.
    /// @param _name The new display name.
    /// @param _badge The new badge URI.
    /// @param _color The new hex color code.
    function _updateLevelDefinition(int64 _level, string memory _name, string memory _badge, string memory _color) internal {
        MemberLevelStorage storage ms = memberLevelStorage();
        LevelDefinition storage levelDef = ms.levelDefinitions[_level];
        require(levelDef.exists, "LibMemberLevel: Level ID does not exist for update");
        levelDef.name = _name;
        levelDef.badge = _badge;
        levelDef.color = _color;
    }

    /// @notice Internal function to mark an existing level definition as inactive (removed).
    /// @dev The definition remains in storage but is flagged as non-existent.
    /// @param _level The unique numeric ID of the level to mark as inactive.
    function _removeLevelDefinition(int64 _level) internal {
        MemberLevelStorage storage ms = memberLevelStorage();
        LevelDefinition storage levelDef = ms.levelDefinitions[_level];
        require(levelDef.exists, "LibMemberLevel: Level ID does not exist for removal");
        levelDef.exists = false;
    }

    /// @notice Internal function to retrieve the full definition of a specific member level.
    /// @param _level The numeric ID of the level to retrieve.
    /// @return A `LevelDefinition` struct containing all details of the level.
    function _getLevelDefinition(int64 _level) internal view returns (LevelDefinition memory) {
        MemberLevelStorage storage ms = memberLevelStorage();
        return ms.levelDefinitions[_level];
    }

    /// @notice Internal function to retrieve an array of all currently active member level definitions.
    /// @dev Iterates through `allLevelIds` and filters for `exists == true`.
    /// @return An array of `LevelDefinition` structs.
    function _getAllLevelDefinitions() internal view returns (LevelDefinition[] memory) {
        MemberLevelStorage storage ms = memberLevelStorage();
        uint256 activeCount = 0;
        // First pass to count active definitions for array initialization
        for (uint256 i = 0; i < ms.allLevelIds.length; i++) {
            if (ms.levelDefinitions[ms.allLevelIds[i]].exists) {
                activeCount++;
            }
        }
        LevelDefinition[] memory definitions = new LevelDefinition[](activeCount);
        uint256 currentIdx = 0;
        // Second pass to populate the array with active definitions
        for (uint256 i = 0; i < ms.allLevelIds.length; i++) {
            int64 levelId = ms.allLevelIds[i];
            if (ms.levelDefinitions[levelId].exists) {
                definitions[currentIdx] = ms.levelDefinitions[levelId];
                currentIdx++;
            }
        }
        return definitions;
    }
} 