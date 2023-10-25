pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

import "../internals/iMembers.sol";

/// @title Members Contract Interface
/// @notice This interface provides a set of functions for managing membership ranks and bounties.
interface IMembers {

    /// @notice Retrieves the rank history of a user up to a certain depth.
    /// @param user The address of the user.
    /// @param depth The maximum depth of the rank history.
    /// @return rank_ An array of MemberRank structs representing the user's rank history.
    function getUserRankHistory(address user, uint64 depth) external returns (LibMembers.MemberRank[] memory rank_);

    /// @notice Sets the members' ranks in a permissioned manner using Merkle proofs.
    /// @param leaves An array of MerkleLeaf structs containing the members' rank data.
    function setMembersRankPermissioned(LibMembers.Leaf[] memory leaves) external;

    /// @notice Sets the members' ranks using Merkle proofs and flags indicating if the rank should be updated.
    
    /// @param leaves An array of MerkleLeaf structs containing the members' rank data.
    function setMembersRanks(uint8 v, bytes32 r, bytes32 s, address owner, uint256 nonce, LibMembers.Leaf memory leaves) external;

    /// @notice Adds an amount to the bounty balance.
    /// @param amount The amount to be added.
    function addBountyBalance(uint256 amount) external;

    /// @notice Removes an amount from the bounty balance.
    /// @param amount The amount to be removed.
    function removeBountyBalance(uint256 amount) external;


}
