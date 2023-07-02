pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;

import "hardhat/console.sol";

import "./ERC1155/iERC1155Transfer.sol";
import "../libraries/LibMembers.sol";
import "../libraries/LibERC1155.sol";
import "../libraries/LibDiamond.sol";
import "../libraries/utils/Incrementer.sol";
import "../libraries/verification/MemberVerification.sol";
import "../libraries/LibModerator.sol";
import "./Moderators/ModeratorModifiers.sol";

contract iMembers is iERC1155Transfer, ModeratorModifiers {
    //history is to save gas on not having to prove every time
    using Incrementer for bytes28;
    using Incrementer for bytes8;
    enum BountyAccountChange {
        Positive,
        Negative
    }

    event Bounty(address receiver, uint256 bountyUp, uint256 bountyUpRate, uint256 bountiesDown, uint256 bountyDownRate);
    event BountyBalanceChange(uint256 amount, BountyAccountChange direction);

    function _initialization(address _bountyAddress, uint256 _currencyId, uint256 _maxBalance) internal {
        _setBountyAddress(_bountyAddress);
        _setBountyCurrencyId(_currencyId);
        _setBountyMaxBalance(_maxBalance);
    }

    //
    //MODERATOR
    function _setMembersRankPermissioned(LibMembers.Leaf[] memory leaves) internal moderatorMemberPermission {
        __changeMemberRanks(leaves);
    }

    function _setMembersRanks(
        uint8 v,
        bytes32 r,
        bytes32 s,
        address owner,
        uint256 nonce,
        LibMembers.Leaf[] memory leaves
    ) internal {
        MemberRecover.executeMyFunctionFromSignature(v, r, s, owner, nonce, leaves);
        __changeMemberRanks(leaves);
    }

    function __changeMemberRanks(LibMembers.Leaf[] memory leaves) private {
        LibMembers.MembersStorage storage ms = LibMembers.memberStorage();
        uint128 bountiesUp;
        uint128 bountiesDown;
        for (uint256 i; i < leaves.length; i++) {
            (address _user, uint48 _timestamp, uint32 _rank) = (leaves[i].memberAddress, leaves[i].memberRank.timestamp, leaves[i].memberRank.rank);
            bytes8 maxIndex = ms.memberRankPointer[_user];

            bytes28 _currentKey = LibMembers.createInitialKey(_user, maxIndex);
            if (_timestamp < ms.memberRank[_currentKey].timestamp || _timestamp == block.timestamp) {
                continue;
            }
            bytes28 _incrementedKey = _currentKey.incrementKey();

            ms.memberRankPointer[_user] = maxIndex.incrementIndex();
            ms.memberRank[_incrementedKey] = LibMembers.MemberRank(uint48(block.timestamp), _rank);

            if (maxIndex == bytes8(0)) {
                bountiesUp++;
                continue;
            }
            ms.memberRank[_currentKey].rank < _rank ? bountiesUp++ : bountiesDown++;
        }

        LibMembers.Bounty storage _bounty = LibMembers.getBounty();
        uint256 _bountyUpRate = _bounty.upRate;
        uint256 _bountyDownRate = _bounty.downRate;
        uint256 bounty = bountiesUp * _bountyUpRate + bountiesDown * _bountyDownRate;
        _safeTransferFrom(_bounty.bountyAddress, msgSender(), _bounty.currencyId, bounty, "");

        emit Bounty(msgSender(), bountiesUp, _bounty.upRate, bountiesDown, _bounty.downRate);
    }

    /**
     * Bounty Methods
     */

    function _addBountyBalance(uint256 amount) internal {
        LibERC1155.ERC1155Storage storage es = LibERC1155.erc1155Storage();
        LibMembers.Bounty storage _bounty = LibMembers.getBounty();
        uint256 bountyBalance;
        uint256 newAmount;

        bountyBalance = LibERC1155.getBalance(_bounty.currencyId, _bounty.bountyAddress);
        //get bountyBalance(bountyAddress, bountyCurrencyId)

        newAmount = bountyBalance + amount;
        require(newAmount <= _bounty.maxBalance, "BMB: New bounty balance exceeds bountyMaxBalance");
        //tranfer msgSender, currency
        _safeTransferFrom(msgSender(), _bounty.bountyAddress, _bounty.currencyId, amount, "");
        emit BountyBalanceChange(amount, BountyAccountChange.Positive);
    }

    function _removeBountyBalance(uint256 amount) internal {
        LibMembers.MembersStorage storage ms = LibMembers.memberStorage();
        LibERC1155.ERC1155Storage storage es = LibERC1155.erc1155Storage();

        LibMembers.Bounty storage _bounty = LibMembers.getBounty();

        _safeTransferFrom(_bounty.bountyAddress, LibDiamond.contractOwner(), _bounty.currencyId, amount, "");
        emit BountyBalanceChange(amount, BountyAccountChange.Negative);
    }

    //permissioned OWNER ONLY
    function _setBountyCurrencyId(uint256 currencyId) internal {
        LibMembers.Bounty storage _bounty = LibMembers.getBounty();

        _bounty.currencyId = currencyId;
    }

    function _setBountyMaxBalance(uint256 maxBalance) internal {
        LibMembers.Bounty storage _bounty = LibMembers.getBounty();
        _bounty.maxBalance = maxBalance;
    }

    function _setBountyAddress(address _bountyAddress) internal {
        require(_bountyAddress != address(0), "Bounty address cannot equal the zero address.");
        LibMembers.Bounty storage _bounty = LibMembers.getBounty();

        _bounty.bountyAddress = _bountyAddress;
    }

    function _rankHistory(address user, uint64 depth) internal  returns (LibMembers.MemberRank[] memory rankHistory_){
        bytes28 key;
        uint64 _maxLoops;
        uint64 _maxIndex64;
        bytes8 _maxIndex =  LibMembers.memberStorage().memberRankPointer[ user ];
        _maxIndex64 = uint64( _maxIndex );
        key = LibMembers.createInitialKey(user,_maxIndex);

        _maxLoops = _maxIndex64 < depth ? _maxIndex64 : depth;
        rankHistory_ = new LibMembers.MemberRank[]( _maxLoops );

        for( uint64 i; i < _maxLoops; i++){
            console.logBytes28(key);
            rankHistory_[_maxLoops - i - 1] =  LibMembers.memberStorage().memberRank[ key ];
            console.log(rankHistory_[i].timestamp);
            key = key.decrementKey();
        }
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
     * an internal call.
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
