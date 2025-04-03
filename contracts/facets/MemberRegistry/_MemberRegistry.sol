// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18; // Updated to a recent version

import { iOwnership } from "../Ownership/_Ownership.sol"; // Assumed interface/contract
import { LibMemberRegistry } from "./LibMemberRegistry.sol";

/// @title iMemberRegistry Internal Logic Contract
/// @notice Holds the internal business logic for member registration, username mapping, and recovery.
/// Designed to be called by external facet functions which enforce access control.
contract iMemberRegistry is iOwnership {

    /// @notice Time window required before recovery can be finalized (e.g., 2 weeks).
    uint32 public constant VERIFICATION_TIME = 14 days; // Using time units for clarity

    // --- Events ---

    /// @dev Emitted when a recovery action status changes (Initiated, Finalized, Cancelled).
    /// @param username The username associated with the action.
    /// @param initiatorOrTargetAddress The address initiating, finalizing, or cancelling the action.
    /// @param recoveryStatus The status of the recovery action.
    /// @param stakeAmount The amount staked (for Initiation) or 0 (for Finalized/Cancelled).
    event RecoveryAction(
        string username,
        address indexed initiatorOrTargetAddress,
        LibMemberRegistry.RecoveryStatus recoveryStatus,
        uint256 stakeAmount
    );

    /// @dev Emitted when a user's username <-> address mapping is successfully set or updated via registration or recovery.
    /// @param username The registered username.
    /// @param userAddress The user's associated address.
    event UserRegistered(string username, address indexed userAddress);

    /// @dev Emitted when the registry Merkle root is updated by the owner.
    /// @param newMerkleRoot The new Merkle root hash.
    /// @param timestamp The time the root was updated.
    event RegistryMerkleRootUpdated(bytes32 newMerkleRoot, uint256 timestamp);

    /// @dev Emitted when the default recovery stake amount is updated by the owner.
    /// @param newStakeAmount The new default stake amount in wei.
    event DefaultRecoveryStakeUpdated(uint256 newStakeAmount);

     /// @dev Emitted when a user-specific recovery stake amount is updated by the owner.
     /// @param username The username for which the specific stake is set.
     /// @param newStakeAmount The new specific stake amount in wei.
    event UserSpecificRecoveryStakeUpdated(string username, uint256 newStakeAmount);

    // --- Owner Functions ---

    /// @notice Sets the Merkle root used for verifying registrations.
    /// @dev Should only be callable by the owner via an external facet.
    /// @param _newRoot The new Merkle root hash.
    function _setRegistryMerkleRoot(bytes32 _newRoot) internal {
        LibMemberRegistry.MemberRegistryStorage storage mrs = LibMemberRegistry.memberRegistryStorage();
        mrs.registryMerkleRoot = _newRoot;
        mrs.registryMerkleRootTimestamp = uint32(block.timestamp);  
        emit RegistryMerkleRootUpdated(_newRoot, block.timestamp);
    }

    /// @notice Sets the default amount of ETH required to initiate recovery.
    /// @dev Should only be callable by the owner via an external facet.
    /// @param _stakeAmount The default stake amount in wei.
    function _setDefaultRecoveryStake(uint256 _stakeAmount) internal {
        LibMemberRegistry.MemberRegistryStorage storage mrs = LibMemberRegistry.memberRegistryStorage();
        mrs.defaultRecoveryStake = _stakeAmount; 
        emit DefaultRecoveryStakeUpdated(_stakeAmount);
    }

     /// @notice Sets or clears a user-specific amount of ETH required to initiate recovery for a given username.
     /// @dev Should only be callable by the owner via an external facet. Set to 0 to revert to default.
     /// @param _username The username to set the specific stake for.
     /// @param _stakeAmount The specific stake amount in wei (or 0 to use default).
    function _setUserSpecificRecoveryStake(string memory _username, uint256 _stakeAmount) internal {
        LibMemberRegistry.MemberRegistryStorage storage mrs = LibMemberRegistry.memberRegistryStorage();
        require(bytes(_username).length > 0, "Username cannot be empty");
        mrs.userSpecificRecoveryStake[_username] = _stakeAmount;  
        emit UserSpecificRecoveryStakeUpdated(_username, _stakeAmount);
    }


    // --- Registration Logic ---

    /**
     * @notice Verifies a Merkle proof to register a username-address pair.
     * @dev Requires that neither the username nor the address are already registered.
     * Assumes the external calling function validates sender if needed.
     * Uses the currently set registryMerkleRoot for verification.
     * @param _leaf The username and address data derived from the Merkle tree leaf.
     * @param _merkleProof Array of hashes to verify the leaf against the root.
     */
    function _verifyAndRegisterUsername(LibMemberRegistry.Leaf calldata _leaf, bytes32[] calldata _merkleProof) internal {
        LibMemberRegistry.MemberRegistryStorage storage mrs = LibMemberRegistry.memberRegistryStorage();
        require(bytes(_leaf.username).length > 0, "Username cannot be empty");
        require(_leaf.userAddress != address(0), "Address cannot be zero");

        // Prevent overwrites
        require(mrs.usernameToAddress[_leaf.username] == address(0), "Username already taken");
        require(bytes(mrs.addressToUsername[_leaf.userAddress]).length == 0, "Address already has username");

        // Verify proof against the current root
        bytes32 leafHash = keccak256(abi.encodePacked(_leaf.username, _leaf.userAddress));
        require(_verifyMerkleProof(_merkleProof, mrs.registryMerkleRoot, leafHash), "Invalid Merkle proof");

        // Set mappings
        mrs.addressToUsername[_leaf.userAddress] = _leaf.username;
        mrs.usernameToAddress[_leaf.username] = _leaf.userAddress;

        emit UserRegistered(_leaf.username, _leaf.userAddress);
    }

    /**
      * @dev Helper function to verify Merkle proofs. Standard implementation.
      * @param proof The proof elements.
      * @param root The Merkle root.
      * @param leaf The leaf hash being verified.
      * @return bool True if the proof is valid, false otherwise.
      */
    function _verifyMerkleProof(bytes32[] calldata proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length;) {
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

    // --- Recovery Logic ---

    /// @notice Initiates the recovery process for a username. Requires ETH stake.
    /// @dev Must be payable. Stake amount determined by userSpecific or default setting.
    /// Records the caller as the potential new address and sets the recovery timestamp.
    /// @param username The username to start recovery for.
    function _initiateUsernameRecovery(string memory username) internal  {
        LibMemberRegistry.MemberRegistryStorage storage mrs = LibMemberRegistry.memberRegistryStorage();
        require(mrs.usernameToAddress[username] != address(0), "Username not registered"); // Must exist to recover

        // Determine required stake
        uint256 requiredStake = mrs.userSpecificRecoveryStake[username];
        if (requiredStake == 0) {
            requiredStake = mrs.defaultRecoveryStake;
        }

        require(msg.value == requiredStake, "Incorrect stake amount provided");

        // Prevent overwriting an active recovery by the same initiator for simplicity,
        // but allow a *different* initiator to start a new attempt (overwriting previous attempt).
        LibMemberRegistry.Recovery storage recoveryInfo = mrs.usernameToRecoveryAddress[username];
         require(recoveryInfo.userNewAddress != msg.sender || recoveryInfo.recoveryTimestamp == 0, "Recovery already initiated by you");

   
        mrs.usernameToRecoveryAddress[username] = LibMemberRegistry.Recovery({  
            userNewAddress: msg.sender,
            recoveryTimestamp: uint32(block.timestamp + VERIFICATION_TIME), 
            stakerAddress: msg.sender, // Staker is the initiator
            stakedAmount: msg.value
        });

        emit RecoveryAction(username, msg.sender, LibMemberRegistry.RecoveryStatus.Initiated, msg.value);
    }

    /// @notice Finalizes the recovery process after the verification time has passed.
    /// @dev Can only be called by the address that initiated the recovery.
    /// Updates username mapping to the new address, deletes the old address link, and returns the stake.
    /// Requires the target address (caller) to not already have a username assigned.
    /// @param username The username being recovered.
    function _finalizeRecovery(string memory username) internal {
        LibMemberRegistry.MemberRegistryStorage storage mrs = LibMemberRegistry.memberRegistryStorage();
        LibMemberRegistry.Recovery memory recoveryInfo = mrs.usernameToRecoveryAddress[username];

        require(recoveryInfo.userNewAddress != address(0), "Recovery not initiated");
        require(recoveryInfo.userNewAddress == msg.sender, "Only recovery initiator can finalize");
        require(block.timestamp >= recoveryInfo.recoveryTimestamp, "Verification period not passed");

        // Check if target address (sender) already has a username
        require(bytes(mrs.addressToUsername[msg.sender]).length == 0, "Finalizing address already has username");

        // Store old address before updating mapping
        address oldAddress = mrs.usernameToAddress[username];

        // Update mappings via internal helper (which includes its own checks)
        // Note: This sets username -> msg.sender and msg.sender -> username
         _updateUsernameAddressPair(username, msg.sender);

         // Clean up the recovery state BEFORE transferring stake
         delete mrs.usernameToRecoveryAddress[username];

        // Delete the old address mapping link IF it's different from the new one
        if (oldAddress != address(0) && oldAddress != msg.sender) {
            delete mrs.addressToUsername[oldAddress];
        }

        // Return stake to the initiator (now the new owner of the username)
        _safeTransferETH(recoveryInfo.stakerAddress, recoveryInfo.stakedAmount);

        emit RecoveryAction(username, msg.sender, LibMemberRegistry.RecoveryStatus.Finalized, 0); // Stake returned
    }

    /// @notice Cancels an ongoing recovery process.
    /// @dev Can only be called by the original address associated with the username. Returns stake to initiator.
    /// @param username The username for which to cancel recovery.
    function _cancelRecovery(string memory username) internal {
        LibMemberRegistry.MemberRegistryStorage storage mrs = LibMemberRegistry.memberRegistryStorage();
        address currentRegisteredAddress = mrs.usernameToAddress[username];
        LibMemberRegistry.Recovery memory recoveryInfo = mrs.usernameToRecoveryAddress[username];

        require(currentRegisteredAddress != address(0), "Username not registered");
        require(msg.sender == currentRegisteredAddress, "Only current username owner can cancel");
        require(recoveryInfo.userNewAddress != address(0), "No active recovery to cancel");

        // Store details before deleting
        address staker = recoveryInfo.stakerAddress;
        uint256 stake = recoveryInfo.stakedAmount;

        // Delete recovery state FIRST
        delete mrs.usernameToRecoveryAddress[username];

        // Return stake to the original staker
        _safeTransferETH(staker, stake);

        emit RecoveryAction(username, msg.sender, LibMemberRegistry.RecoveryStatus.Cancelled, 0); // Stake returned
    }

    // --- Direct Setting (Owner Batch) & Helpers ---

    /// @dev Internal helper to securely set/update the bidirectional username-address mapping.
    /// Performs necessary checks to prevent overwriting unless explicitly intended (which it isn't here).
    /// @param _username The username to set.
    /// @param _userAddress The address to associate with the username.
    function _updateUsernameAddressPair(string memory _username, address _userAddress) internal {
        LibMemberRegistry.MemberRegistryStorage storage mrs = LibMemberRegistry.memberRegistryStorage();

        // Basic validation
        require(bytes(_username).length > 0, "Username cannot be empty");
        require(_userAddress != address(0), "Address cannot be zero");

        // Check for existing mappings to prevent overwrite (can be relaxed if updates are needed)
        require(mrs.usernameToAddress[_username] == address(0) || mrs.usernameToAddress[_username] == _userAddress, "Username already taken by different address");
        // Check if the address already has a *different* username
        // Read the stored username for this address into memory
        string memory storedUsername = mrs.addressToUsername[_userAddress]; 

        // Allow if stored username is empty OR if the hashes of stored and new username match
        require(
            bytes(storedUsername).length == 0 || // Check if stored string is empty
            keccak256(abi.encodePacked(storedUsername)) == keccak256(abi.encodePacked(_username)), // Compare hashes
            "Address already has different username"
        );
  
        // Set mappings
        mrs.usernameToAddress[_username] = _userAddress;
        mrs.addressToUsername[_userAddress] = _username;

        // Note: UserRegistered event is emitted by the calling function (e.g., _verifyAndRegisterUsername, _finalizeRecovery, _batchSetUsernames)
        // This keeps the helper focused solely on the storage update.
    }


    /// @notice Sets username-address pairs directly by the owner.
    /// @dev Should only be callable by the owner via an external facet.
    /// Performs overwrite checks for each entry. Emits UserRegistered for each successful set.
    /// @param usernames Array of usernames.
    /// @param userAddresses Array of corresponding addresses.
    function _batchSetUsernames(string[] memory usernames, address[] memory userAddresses) internal {
        LibMemberRegistry.MemberRegistryStorage storage  mrs = LibMemberRegistry.memberRegistryStorage();
        uint256 length = usernames.length;
        require(length == userAddresses.length, "Input arrays must have same length");

        for (uint256 i = 0; i < length;) {
            string memory _username = usernames[i];
            address _userAddress = userAddresses[i];

            // Use the helper function which includes checks
             _updateUsernameAddressPair(_username, _userAddress);

            // Emit event for successful registration/update in the batch
            emit UserRegistered(_username, _userAddress);

            // Use unchecked arithmetic for safe loop increment
            unchecked { ++i; }
        }
        // Note: Removed UsersRegistered event, emitting singular UserRegistered is better for indexing.
    }

    /// @dev Internal helper for safely transferring ETH. Includes check for success.
    function _safeTransferETH(address to, uint256 amount) internal {
        if (amount > 0) {
            (bool success, ) = to.call{value: amount}("");
            require(success, "ETH transfer failed");
        }
    }
}