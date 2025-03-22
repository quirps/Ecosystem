pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

import "./_Members.sol"; 

/// @title Members Contract Interface
/// @notice This interface provides a set of functions for managing membership ranks and bounties.
interface IMembers {
 
 /**
     * @dev Verifies Merkle proof and sets user's level
     * @param _leaf Level to assign to the user
     * @param _merkleProof Array of hashed data to verify proof
     */
    function verifyAndSetLevel(LibMemberLevel.Leaf memory _leaf, bytes32[] calldata _merkleProof) external;

    /**
     * @dev Batch set levels for multiple addresses (permissioned function)
     * @param _leaves user resource denoting their membership status
     */
    function batchSetLevels(LibMemberLevel.Leaf[] calldata _leaves) external;

    /**
     * @dev Returns the level info for a given address
     * @param _user Address to query
     * @return level and timestamp of the user
     */
    function getMemberLevelStruct(address _user) external view returns (uint32 level, uint32 timestamp);

    /**
     * @dev Returns the level info for a given address
     * @param _user Address to query
     */
    function getMemberLevel(address _user) external view returns (uint32 memberLevel_);

    /**
     * @dev Bans a user by setting their level to 0
     * @param _user Address of the user to ban
     */
    function banMember(address _user) external;
}
