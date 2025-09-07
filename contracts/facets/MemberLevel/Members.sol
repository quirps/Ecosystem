// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import {IMembers} from "./IMembershipLevels.sol";
import {iMembers} from "./_MembershipLevels.sol";
import {LibMemberLevel} from "./LibMemberLevel.sol";
// Importing OpenZeppelin's Ownable for basic access control

/// @title MembershipLevels
/// @notice This is the external facet contract for managing membership levels within a Diamond architecture.
/// It exposes the functions defined in `IMembershipLevels` and delegates their execution to the
/// `MembershipLevelsInternal` contract, acting as a proxy.
/// Administrative functions are protected by `onlyOwner` modifier inherited from OpenZeppelin's Ownable.
contract MembershipLevels is IMembers, iMembers {

    /// @inheritdoc IMembers
    function verifyAndSetLevel(LibMemberLevel.Leaf memory _leaf, bytes32[] calldata _merkleProof) external override {
        // Delegates to the internal logic function
        _verifyAndSetLevel(_leaf, _merkleProof);
    }

    /// @inheritdoc IMembers
    function batchSetLevels(LibMemberLevel.Leaf[] calldata _leaves, bytes32[][] calldata _merkleProofs) external override {
        // Delegates to the internal logic function
        _batchSetLevels(_leaves, _merkleProofs);
    }

    /// @inheritdoc IMembers
    function banMember(LibMemberLevel.Leaf memory _bannedLeaf, bytes32[] calldata _merkleProof) external override {
        // This function facilitates setting a user's level to a "banned" tier via Merkle proof.
        // The `_bannedLeaf` must be pre-constructed off-chain with the appropriate banned level ID and timestamp.
        _banMember(_bannedLeaf, _merkleProof);
    }

    /// @inheritdoc IMembers
    function getMemberLevelStruct(address _user) external view override returns (int64 level, uint32 timestamp) {
        // Delegates to the internal logic function
        return _getMemberLevelStruct(_user);
    }

    /// @inheritdoc IMembers
    function getMemberLevel(address _user) external view override returns (int64 memberLevel_) {
        // Delegates to the internal logic function
        return _getMemberLevel(_user);
    }

    /// @inheritdoc IMembers
    function addLevelDefinition(int64 _level, string calldata _name, string calldata _badge, string calldata _color) external override onlyOwner {
        // Delegates to the internal logic function; restricted to owner
        _addLevelDefinition(_level, _name, _badge, _color);
    }

    /// @inheritdoc IMembers
    function updateLevelDefinition(int64 _level, string calldata _name, string calldata _badge, string calldata _color) external override onlyOwner {
        // Delegates to the internal logic function; restricted to owner
        _updateLevelDefinition(_level, _name, _badge, _color);
    }

    /// @inheritdoc IMembers
    function removeLevelDefinition(int64 _level) external override onlyOwner {
        // Delegates to the internal logic function; restricted to owner
        _removeLevelDefinition(_level);
    }

    /// @inheritdoc IMembers
    function getLevelDefinition(int64 _level) external view override returns (LibMemberLevel.LevelDefinition memory levelDefinition) {
        // Delegates to the internal logic function
        return _getLevelDefinition(_level);
    }

    /// @inheritdoc IMembers
    function getAllLevelDefinitions() external view override returns (LibMemberLevel.LevelDefinition[] memory levelDefinitions) {
        // Delegates to the internal logic function
        return _getAllLevelDefinitions();
    }

    /// @inheritdoc IMembers
    function getLevelNames() external view override returns (string[] memory levelNames) {
        // Delegates to the internal logic function
        return _getLevelNames();
    }

    /// @inheritdoc IMembers
    function setMerkleRoot(bytes32 _newRoot) external override onlyOwner {
        // Delegates to the internal logic function; restricted to owner
        _setMerkleRoot(_newRoot);
    }
}