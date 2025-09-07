// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import { LibMemberRegistry } from "./LibMemberRegistry.sol";

/// @title IMemberRegistryFacet
/// @notice An interface for the MemberRegistry contract.
/// It contains all external and public function declarations
/// without their implementation, events, or errors.
interface IMemberRegistry {
    // --- Owner Functions ---

    /// @notice Sets the Merkle root used for verifying registrations.
    /// @param _newRoot The new Merkle root hash.
    function setRegistryMerkleRoot(bytes32 _newRoot) external;

    /// @notice Sets the default ETH stake required for recovery initiation.
    /// @param _stakeAmount The default stake amount in wei.
    function setDefaultRecoveryStake(uint256 _stakeAmount) external;

    /// @notice Sets a user-specific ETH stake for recovery initiation.
    /// @param _username The username to set the specific stake for.
    /// @param _stakeAmount The specific stake amount in wei (0 to use default).
    function setUserSpecificRecoveryStake(string memory _username, uint256 _stakeAmount) external;

    /// @notice Sets multiple username-address pairs directly.
    /// @param usernames Array of usernames.
    /// @param userAddresses Array of corresponding addresses.
    function batchSetUsernames(string[] memory usernames, address[] memory userAddresses) external;

    // --- User Functions ---

    /// @notice Registers a user by verifying a Merkle proof against the current root.
    /// @param _leaf The username and address data derived from the Merkle tree leaf.
    /// @param _merkleProof Array of hashes to verify the leaf against the root.
    function verifyAndRegisterUsername(LibMemberRegistry.Leaf calldata _leaf, bytes32[] calldata _merkleProof) external;

    /// @notice Initiates the recovery process for a registered username. Requires ETH stake.
    /// @param username The username to start recovery for.
    function initiateUsernameRecovery(string memory username) external payable;

    /// @notice Finalizes the username recovery process after the verification time has passed.
    /// @param username The username being recovered.
    function finalizeRecovery(string memory username) external;

    /// @notice Cancels an ongoing username recovery process.
    /// @param username The username for which to cancel recovery.
    function cancelRecovery(string memory username) external;

    // --- View Functions ---

    /// @notice Gets the username associated with a given address.
    /// @param _userAddress The address to query.
    /// @return The associated username, or an empty string if none is set.
    function getUsername(address _userAddress) external view returns (string memory);

    /// @notice Gets the address associated with a given username.
    /// @param _username The username to query.
    /// @return The associated address, or the zero address if the username is not registered.
    function getAddress(string memory _username) external view returns (address);

    /// @notice Checks if a username is already registered to any address.
    /// @param _username The username to check.
    /// @return True if the username is registered, false otherwise.
    function isUsernameTaken(string memory _username) external view returns (bool);

    /// @notice Checks if an address already has a username registered to it.
    /// @param _userAddress The address to check.
    /// @return True if the address has an associated username, false otherwise.
    function doesAddressHaveUsername(address _userAddress) external view returns (bool);

    /// @notice Gets the current recovery status information for a specific username.
    /// @param _username The username to query recovery status for.
    /// @return The recovery struct. Fields will be zero/default if no recovery process is active.
    function getRecoveryInfo(string memory _username) external view returns (LibMemberRegistry.Recovery memory);

    /// @notice Gets the currently active Merkle root being used for registration proofs.
    /// @return The current Merkle root hash.
    function getRegistryMerkleRoot() external view returns (bytes32);

    /// @notice Gets the timestamp (Unix epoch) when the current Merkle root was set.
    /// @return The timestamp of the last Merkle root update.
    function getRegistryMerkleRootTimestamp() external view returns (uint256);

    /// @notice Gets the default amount of ETH (in wei) required to initiate recovery.
    /// @return The default stake amount.
    function getDefaultRecoveryStake() external view returns (uint256);

    /// @notice Gets the user-specific ETH stake (in wei) required for recovery initiation, if one is set.
    /// @param _username The username to query the specific stake for.
    /// @return The specific stake amount in wei (returns 0 if no specific stake is set, meaning use default).
    function getUserSpecificRecoveryStake(string memory _username) external view returns (uint256);

    /// @notice Gets the required waiting period (in seconds) before recovery can be finalized.
    /// @return The verification time constant in seconds.
    function getVerificationTime() external view returns (uint32);
}
