// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/LibMembers.sol";
import "../libraries/merkleVerify/MembersVerify.sol";
/**
 * @title IMembers
 * @dev Interface for the Members contract.
 */
interface IMembers {
    
    /**
     * @notice Initialize the contract with a bounty address
     * @param _bountyAddress The address of the bounty
     */
    function initialization(address _bountyAddress) external;
    
    /**
     * @notice Change rank labels
     * @param _oldRankLabels The array of old rank labels to be changed
     * @param _newRankLabels The array of new rank labels
     */
    function changeRankLabels(bytes30[] memory _oldRankLabels, bytes30[] memory _newRankLabels) external;
    
    /**
     * @notice Get user rank history
     * @param user The user's address
     * @return memberHistory_ An array of MemberRank structs representing the user's rank history
     */
    function getUserRankHistory(address user) external view returns (LibMembers.MemberRank[] memory memberHistory_);
    
    /**
     * @notice Get user rank label
     * @param user The user's address
     * @return rankLabel_ The user's current rank label
     */
    function getUserRankLabel(address user) external view returns (bytes30 rankLabel_);
    
    /**
     * @notice Get user rank
     * @param user The user's address
     * @return rank_ The user's current rank
     */
    function getUserRank(address user) external view returns (uint16 rank_);
    
    /**
     * @notice Change ranks
     * @param _rankLabels The array of rank labels to be added or deleted
     * @param _ranks The array of ranks to be given to new labels (ignored for deletion)
     * @param _delete The array indicating whether to delete a rank label or not
     * @param _index The array of indices of rank labels in storage (needed for deletion)
     */
    function changeRanks(bytes30[] memory _rankLabels, uint16[] memory _ranks, bool[] memory _delete, uint16[] memory _index) external;
    
    /**
     * @notice Set member rank permissioned
     * @param _member The array of member addresses
     * @param _rankLabel The array of rank labels to be set for the members
     */
    function setMemberRankPermissioned(address[] memory _member, bytes30[] memory _rankLabel) external;
    
    /**
     * @notice Set members' ranks
     * @param proof The array of proofs
     * @param proofFlags The array of proof flags
     * @param leaves The array of Leaf structs
     */
    function setMembersRanks(bytes32[] memory proof, bool[] memory proofFlags, MembersVerify.Leaf[] memory leaves) external;
    
    /**
     * @notice Add bounty balance
     * @param amount The amount of bounty balance to be added
     */
    function addBountyBalance(uint256 amount) external;
    
    /**
     * @notice Remove bounty balance
     * @param amount The amount of bounty balance to be removed
     */
    function removeBountyBalance(uint256 amount) external;
    
    /**
     * @notice Set the bounty currency ID
     * @param currencyId The ID of the bounty currency
     */
    function setBountyCurrencyId(uint256 currencyId) external;
    
    /**
     * @notice Set the maximum bounty balance
     * @param maxBalance The maximum bounty balance
     */
    function setBountyMaxBalance(uint256 maxBalance) external;
    
}