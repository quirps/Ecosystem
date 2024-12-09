pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;

import "../Tokens/ERC1155/ERC1155Transfer.sol";
import "../MemberRankings/_Members.sol";  
import "../../libraries/merkleVerify/MembersVerify.sol"; 
import "./IMembers.sol";

contract Members is IMembers, iMembers { 

    function setBountyConfig( uint256 _maxBalance, address _bountyAddress, uint256 _upRate, uint256 _downRate) external {
        _setBountyConfig(_maxBalance, _bountyAddress, _upRate, _downRate);
    }
    function getUserRankHistory(address user, uint64 depth) external returns (LibMembers.MemberRank[] memory rank_) {
        rank_ = _rankHistory(user, depth);
        //rank_ = LibMembers.rankHistory(user, depth);
    }
    function getRank(address user) external returns (uint32 rank_){
        rank_ = _getRank(user);
    }
    //
    function setMembersRankPermissioned(LibMembers.Leaf[] memory leaves) external {
        _setMembersRankPermissioned(leaves);
    }

    function setMemberRankOwner( LibMembers.Leaf[] memory leaves) external {
        isEcosystemOwnerVerification();
        __changeMemberRanks(leaves);
    }

    function setMembersRanks(uint8 v, bytes32 r, bytes32 s, address owner, uint256 nonce, LibMembers.Leaf memory leaf) external {
        _setMembersRanks(v, r, s, owner, nonce, leaf);
    }

    /**
     * Bounty Methods
     */

    function addBountyBalance(uint256 amount) external {
        _addBountyBalance(amount);
    }

    function removeBountyBalance(uint256 amount) external {
        _removeBountyBalance(amount);
    }

    function getBounty() external view returns (Bounty memory bounty_) {
        bounty_ = _getBounty();
    }
    /**
     * Implement an optimized version of erc1155 specific for bounties? Or unoptimized
     * version for now. But this certainly opens up the possibility of having
     * different optimizations of similar type for the same contract.
     *
     * I.e. transfer in this setting would have a bounty account which transfes??
     * Maybe no optmiizaiton, just use un-optimized
     *
     * Do need to import minimal transfer requirements as a typical optimization over
     * an external call.
     * Create Bounty Cap, Bounty per user rate,
     */

    // and mapping?
    /**
     * How would you change a rank label? Just create a mapping with the same rank
     * as the one you're changing.
     * So if someone is current rank n, and their label gets changed, then needs to
     * get updated at some point.
     *
     */
}

/**
 * What is a good way to generalize this protocol to third parties? Ecosystems
 * should dictate the reward structure for members? Or third party dictates?
 * Maybe third party provides default and ecosystem can set later. Why would
 * third parties care about membership? To attract members, they have the opportunity
 * to receieve extra rewards.
 */

/**
 * How to do ranks? Want foreign parties to use members and ranks structures,
 * is there a way to coordinate this?
 *
 * General Layout:
 *      Ecosystems will have a ranking system amongst their members.
 *      Members is a discrete, well-ordered set.
 *      Every Member has a rank associated with it.
 *      This rank is given to the member by the owner, but isn't updated
 *          until someone proves it on-chain. This allows time for a user's
 *          true rank not be seen for some time.
 * What if members were forced to deposit a small amount? What if owner did it?
 * How would the rate be determined, changed? How to choose the bounty?
 * Bounty has several factors:
 *      - Need to designate allowed funds MEV can take
 *      - Calculate gas cost
 *      - How to calculate cost of token? Need exchange with liquidity
 *        This is only real mainstream way to solve this problem
 *  Would need to have a crutch available to keep flow going. This requires
 * some semblance of marketable value for another service to use it. What
 * is done until value can be a liquidable asset?
 *
 * For now, setup so owner sets bounty. Liquidable assets will start later.
 * Owner can act as a service for upgrading or merely providing the signed
 * message for the MEV to send with a given bounty. On-Chain can have a hardcap
 * set for any mistake.
 *
 *
 * Now back to 3rd parties, how can they use the membership protocol?
 * They'd want to use it in a way where they try to mirror the reality
 * set in the ecosystem.
 *
 * For the exchange, a user setting liquidity will have their membership taken
 * and liqudity rate changed. If their rank changes, can be updated.
 * How to deal with over-charging? I.E. member can never update and get max
 * rewards.
 *
 * Reward MEV with member-adjustment lag? MEV can take timestamp from decentralized
 * storage and prove that the member's current rank is above the offline level
 * and at an ealier time. What is the reward? Reward would be the excess fee earned
 * from the current true member rank.
 */
