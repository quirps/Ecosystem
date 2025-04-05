// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { LibMemberRegistry } from "./LibMemberRegistry.sol";
import { iMemberRegistry } from "./_MemberRegistry.sol"; 

/// @title MemberRegistryFacet External Interface
/// @notice Provides external functions to interact with the Member Registry system.
/// Handles access control and forwards calls to the internal logic functions.
/// Inherits from iMemberRegistry to access internal functions and state via LibMemberRegistry.
contract MemberRegistry is iMemberRegistry {

    // --- Owner Functions ---
    // (Functions from previous response: setRegistryMerkleRoot, setDefaultRecoveryStake, setUserSpecificRecoveryStake, batchSetUsernames)

    /// @notice EXTERNAL: Sets the Merkle root used for verifying registrations. Owner only.
    /// @param _newRoot The new Merkle root hash.
    function setRegistryMerkleRoot(bytes32 _newRoot) external onlyOwner {
        _setRegistryMerkleRoot(_newRoot);
    }

    /// @notice EXTERNAL: Sets the default ETH stake required for recovery initiation. Owner only.
    /// @param _stakeAmount The default stake amount in wei.
    function setDefaultRecoveryStake(uint256 _stakeAmount) external onlyOwner {
        _setDefaultRecoveryStake(_stakeAmount);
    }

    /// @notice EXTERNAL: Sets a user-specific ETH stake for recovery initiation. Owner only.
    /// @param _username The username to set the specific stake for.
    /// @param _stakeAmount The specific stake amount in wei (0 to use default).
    function setUserSpecificRecoveryStake(string memory _username, uint256 _stakeAmount) external onlyOwner {
        _setUserSpecificRecoveryStake(_username, _stakeAmount);
    }

    /// @notice EXTERNAL: Sets multiple username-address pairs directly. Owner only.
    /// @param usernames Array of usernames.
    /// @param userAddresses Array of corresponding addresses.
    function batchSetUsernames(string[] memory usernames, address[] memory userAddresses) external onlyOwner {
        _batchSetUsernames(usernames, userAddresses);
    }

    // --- User Functions ---
    // (Functions from previous response: verifyAndRegisterUsername, initiateUsernameRecovery, finalizeRecovery, cancelRecovery)

    /// @notice EXTERNAL: Registers a user by verifying a Merkle proof against the current root.
    /// @param _leaf The username and address data derived from the Merkle tree leaf.
    /// @param _merkleProof Array of hashes to verify the leaf against the root.
    function verifyAndRegisterUsername(LibMemberRegistry.Leaf calldata _leaf, bytes32[] calldata _merkleProof) external {
        _verifyAndRegisterUsername(_leaf, _merkleProof);
    }

    /// @notice EXTERNAL: Initiates the recovery process for a registered username. Requires ETH stake.
    /// @param username The username to start recovery for.
    function initiateUsernameRecovery(string memory username) external payable {
        _initiateUsernameRecovery(username);
    }

    /// @notice EXTERNAL: Finalizes the username recovery process after the verification time has passed.
    /// @param username The username being recovered.
    function finalizeRecovery(string memory username) external {
        _finalizeRecovery(username);
    }

    /// @notice EXTERNAL: Cancels an ongoing username recovery process.
    /// @param username The username for which to cancel recovery.
    function cancelRecovery(string memory username) external {
        _cancelRecovery(username);
    }

    // --- View Functions ---

    /// @notice Gets the username associated with a given address.
    /// @param _userAddress The address to query.
    /// @return string The associated username, or an empty string if none is set.
    function getUsername(address _userAddress) external view returns (string memory) {
        LibMemberRegistry.MemberRegistryStorage storage mrs = LibMemberRegistry.memberRegistryStorage();
        return mrs.addressToUsername[_userAddress];
    }

    /// @notice Gets the address associated with a given username.
    /// @param _username The username to query.
    /// @return address The associated address, or the zero address if the username is not registered.
    function getAddress(string memory _username) external view returns (address) {
        LibMemberRegistry.MemberRegistryStorage storage mrs = LibMemberRegistry.memberRegistryStorage();
        return mrs.usernameToAddress[_username];
    }

    /// @notice Checks if a username is already registered to any address.
    /// @param _username The username to check.
    /// @return bool True if the username is registered, false otherwise.
    function isUsernameTaken(string memory _username) external view returns (bool) {
        LibMemberRegistry.MemberRegistryStorage storage mrs = LibMemberRegistry.memberRegistryStorage();
        return mrs.usernameToAddress[_username] != address(0);
    }

    /// @notice Checks if an address already has a username registered to it.
    /// @param _userAddress The address to check.
    /// @return bool True if the address has an associated username, false otherwise.
    function doesAddressHaveUsername(address _userAddress) external view returns (bool) {
        LibMemberRegistry.MemberRegistryStorage storage mrs = LibMemberRegistry.memberRegistryStorage();
        // Check the length of the bytes representation of the string
        return bytes(mrs.addressToUsername[_userAddress]).length > 0;
    }

    /// @notice Gets the current recovery status information for a specific username.
    /// @param _username The username to query recovery status for.
    /// @return recoveryInfo The recovery struct containing the potential new address,
    ///         the timestamp when recovery can be finalized, the staker address, and the staked amount.
    ///         Fields will be zero/default if no recovery process is active for this username.
    function getRecoveryInfo(string memory _username) external view returns (LibMemberRegistry.Recovery memory recoveryInfo) {
        LibMemberRegistry.MemberRegistryStorage storage mrs = LibMemberRegistry.memberRegistryStorage();
        // Directly return the struct stored in the mapping
        recoveryInfo = mrs.usernameToRecoveryAddress[_username];
    }

    /// @notice Gets the currently active Merkle root being used for registration proofs.
    /// @return bytes32 The current Merkle root hash.
    function getRegistryMerkleRoot() external view returns (bytes32) {
        LibMemberRegistry.MemberRegistryStorage storage mrs = LibMemberRegistry.memberRegistryStorage();
        return mrs.registryMerkleRoot;
    }

    /// @notice Gets the timestamp (Unix epoch) when the current Merkle root was set.
    /// @return uint256 The timestamp of the last Merkle root update.
    function getRegistryMerkleRootTimestamp() external view returns (uint256) {
        LibMemberRegistry.MemberRegistryStorage storage mrs = LibMemberRegistry.memberRegistryStorage();
        return mrs.registryMerkleRootTimestamp;
    }

    /// @notice Gets the default amount of ETH (in wei) required to initiate recovery.
    /// @return uint256 The default stake amount.
    function getDefaultRecoveryStake() external view returns (uint256) {
        LibMemberRegistry.MemberRegistryStorage storage mrs = LibMemberRegistry.memberRegistryStorage();
        return mrs.defaultRecoveryStake;
    }

    /// @notice Gets the user-specific ETH stake (in wei) required for recovery initiation, if one is set.
    /// @dev Returns the specific amount set for the user. If this amount is 0, it implies the default stake should be used.
    /// @param _username The username to query the specific stake for.
    /// @return uint256 The specific stake amount in wei (returns 0 if no specific stake is set, meaning use default).
    function getUserSpecificRecoveryStake(string memory _username) external view returns (uint256) {
        LibMemberRegistry.MemberRegistryStorage storage mrs = LibMemberRegistry.memberRegistryStorage();
        return mrs.userSpecificRecoveryStake[_username];
    }

    /// @notice Gets the required waiting period (in seconds) before recovery can be finalized.
    /// @return uint32 The verification time constant in seconds.
    function getVerificationTime() external view returns (uint32) {
        // Access the constant defined in the inherited iMemberRegistry contract
        // Constants defined in inherited contracts are directly accessible.
        return VERIFICATION_TIME;
    }
}