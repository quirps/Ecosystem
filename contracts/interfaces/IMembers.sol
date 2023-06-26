pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

import "../internals/iMembers.sol";

/// @title Members Contract Interface
/// @notice This interface provides a set of functions for managing membership ranks and bounties.
interface IMembers {
    
    /// @notice Initializes the Members contract with the specified bounty address.
    /// @param _bountyAddress The address of the bounty contract.
    function initialization(address _bountyAddress, uint256 _bountyCurrencyId, uint256 _bountyMaxBalance) external;

    /// @notice Retrieves the rank history of a user up to a certain depth.
    /// @param user The address of the user.
    /// @param depth The maximum depth of the rank history.
    /// @return rank_ An array of MemberRank structs representing the user's rank history.
    function getUserRankHistory(address user, uint64 depth) external view returns (LibMembers.MemberRank[] memory rank_);

    /// @notice Sets the members' ranks in a permissioned manner using Merkle proofs.
    /// @param leaves An array of MerkleLeaf structs containing the members' rank data.
    function setMembersRankPermissioned(LibMembers.MerkleLeaf[] memory leaves) external;

    /// @notice Sets the members' ranks using Merkle proofs and flags indicating if the rank should be updated.
    /// @param proof An array of Merkle proofs for each rank leaf.
    /// @param proofFlags An array of flags indicating if the rank should be updated.
    /// @param leaves An array of MerkleLeaf structs containing the members' rank data.
    function setMembersRanks(bytes32[] memory proof, bool[] memory proofFlags, LibMembers.MerkleLeaf[] memory leaves) external;

    /// @notice Adds an amount to the bounty balance.
    /// @param amount The amount to be added.
    function addBountyBalance(uint256 amount) external;

    /// @notice Removes an amount from the bounty balance.
    /// @param amount The amount to be removed.
    function removeBountyBalance(uint256 amount) external;

    /// @notice Sets the currency ID for the bounty.
    /// @param currencyId The currency ID to be set.
    function setBountyCurrencyId(uint256 currencyId) external;

    /// @notice Sets the maximum balance for the bounty.
    /// @param maxBalance The maximum balance to be set.
    function setBountyMaxBalance(uint256 maxBalance) external;

    /// @notice Sets the address of the bounty contract.
    /// @param _bountyAddress The address of the bounty contract.
    function setBountyAddress(address _bountyAddress) external;
}
