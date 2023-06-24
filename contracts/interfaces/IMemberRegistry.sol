// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/LibMemberRegistry.sol";

/// @title iMemberRegistry Interface
/// @dev Responsible for validating members on a particular platform off-chain
///      to a corresponding address in the ecosystem. A simple recovery mechanism
///      is put in place and is expected to expand in the future. 
interface IMemberRegistry {

    /// @dev Initializes the MemberRegistry contract with the verification time
    /// @param _recoveryTime The amount of time it takes for a user to recover
    ///                      a username
    function initializor(uint96 _recoveryTime) external;

    /// @dev Verifies a username with the corresponding owner signature
    ///      starts recovery process if address doesn't match current.
    /// @param username The username to verify
    /// @param _signature The signature verification data
    function verifyUsername(string memory username, LibMemberRegistry.SignatureVerfication memory _signature) external;

    /// @dev Finalizes the recovery of a username
    /// @param username The username to recover
    function finalizeRecovery(string memory username) external;

    /// @dev Cancels the verification process for a username
    /// @param username The username to cancel verification for
    function cancelVerify(string memory username) external;
}