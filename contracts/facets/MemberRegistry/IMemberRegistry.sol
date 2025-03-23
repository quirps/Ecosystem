// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LibMemberRegistry.sol"; 

/// @title iMemberRegistry Interface
/// @dev Responsible for validating members on a particular platform off-chain
///      to a corresponding address in the ecosystem. A simple recovery mechanism
///      is put in place and is expected to expand in the future. 
interface IMemberRegistry {

   function verifyAndUsername(LibMemberRegistry.Leaf memory _leaf, bytes32[] calldata _merkleProof) external;
    function setUsernamePair(string memory username) external;
    function usernameRecovery(string memory username) external;
    function finalizeRecovery(string memory username) external;
    function cancelVerify(string memory username) external;
    function setUsernameAddressPair(string memory username) external;
    function setUsernameOwner(string[] memory username, address[] memory userAddress) external;
}