pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

import "../libraries/merkleVerify/MembersVerify.sol";
import "./ERC1155/iERC1155Transfer.sol";
import "../libraries/LibMembers.sol";
import "../libraries/LibERC1155.sol";
import "../libraries/LibDiamond.sol";

contract iMembers is iERC1155Transfer {
    //history is to save gas on not having to prove every time
    using LibMembers for bytes28;
    enum BountyAccountChange {
        Positive,
        Negative
    }

    event Bounty(address receiver, uint256 bountyUp, uint256 bountyUpRate, uint256 bountiesDown, uint256 bountyDownRate);
    event BountyBalanceChange(uint256 amount, BountyAccountChange direction);

    function _initialization(address _bountyAddress) internal {
        LibMembers.MembersStorage storage ms = LibMembers.memberStorage();
        LibMembers.Bounty storage _bounty = LibMembers.getBounty();
        _bounty.bountyAddress = _bountyAddress;
    }

    function _getUserRankHistory(address user) internal view returns (LibMembers.MemberRank[] memory) {
        LibMembers.MembersStorage storage ms = LibMembers.memberStorage();
        //loop
        LibMembers.PointerMeta memory pointerMeta = ms.memberRankPointer[user];
        LibMembers.MemberRank[] memory _memberRankHistory = new LibMembers.MemberRank[](pointerMeta.length);
        for (uint48 i; i < pointerMeta.length; i++) {
            if (pointerMeta.key == type(uint128).min) {
                break;
            }
            LibMembers.MemberRankBlock memory _memberRankBlock = ms.memberRankBlock[pointerMeta.key];
            _memberRankHistory[i] = _memberRankBlock.memberRank;
            uint192 pointerKey = _memberRankBlock.key;
        }
        return _memberRankHistory;
        // go through pointer -> block -> pointer -> block ...
    }

    function _getUserRank(address user) internal view returns (uint16 rank_) {
        LibMembers.MembersStorage storage ms = LibMembers.memberStorage();
        uint192 _key = ms.memberRankPointer[user].key;
        rank_ = ms.memberRankBlock[_key].memberRank.rank;
    }

    function _addRankBlock(LibMembers.MembersStorage storage ms, address user) private {
        
        // get key of latest block (if exists)
        // if doesnt existt - generate key kec(address), create PointerMeta
        // else - new key kec(key), create PointerMeta
        // get key to previou block from PointerMeta
        //
    }

    function generateKey(address userAddress, uint48 timestamp) internal {
        bytes24(keccak256(abi.encodePacked(userAddress)));
    }

    //
    //MODERATOR 
    function _setMembersRankPermissioned(LibMembers.MerkleLeaf[] memory leaves) internal {
        __changeMemberRanks( leaves );
    }
    function _setMembersRanks(bytes32[] memory proof, bool[] memory proofFlags, LibMembers.MerkleLeaf[] memory leaves) internal {
        MembersVerify.multiProofVerify(proof, proofFlags, leaves);
        __changeMemberRanks( leaves );
    }

    function __changeMemberRanks( LibMembers.MerkleLeaf[] memory leaves ) private {
        LibMembers.MembersStorage storage ms = LibMembers.memberStorage();
        LibMembers.Bounty storage _bounty = LibMembers.getBounty();

        uint128 bountiesUp;
        uint128 bountiesDown;
        for (uint256 i; i < leaves.length; i++) { 
            
            (address _user, uint48 _timestamp, uint32 _rank) = ( leaves[i].user, 
                                                                leaves[i].memberRank.timestamp,
                                                                leaves[i].memberRank.rank);
            bytes8 maxIndex = ms.memberRankPointer[ _user ].maxIndex;

            bytes28 _currentKey = abi.encodePacked( maxIndex, user);
            if( _timestamp < ms.memberRank[_currentKey].timestamp || _timestamp == block.timestamp ){
                continue;
            }
            bytes28 _incrementedKey = _currentKey.increment;
            
            ms.memberRankPointer[ _user ] = maxIndex.increment;
            ms.memberRank[ _incrementedKey ] = LibMembers.MemberRank(block.timestamp, _rank);

            if( maxIndex == type( bytes8 ).min ){
                bountiesUp++;
                continue;
            }
            ms.memberRank[ _currentKey ].rank < _rank ? bountiesUp++ : bountiesDown++;
        }
        uint256 bounty = bountiesUp * _bounty.UpRate + bountiesDown * _bounty.DownRate;

        _safeTransferFrom(_bounty.Address, msgSender(), _bounty.CurrencyId, bounty, "");

        emit Bounty(msgSender(), bountiesUp, _bounty.UpRate, bountiesDown, _bounty.DownRate);
    }

    

    /**
     * Bounty Methods
     */

    function _addBountyBalance(uint256 amount) internal {
        LibERC1155.ERC1155Storage storage es = LibERC1155.erc1155Storage();
        LibMembers.Bounty storage _bounty = LibMembers.getBounty();
        uint256 bountyBalance;
        uint256 newAmount;

        bountyBalance = LibERC1155.getBalance(_bounty.Address, _bounty.CurrencyId);
        //get bountyBalance(bountyAddress, bountyCurrencyId)

        newAmount = bountyBalance + amount;
        require(newAmount <= _bounty.MaxBalance, "New bounty balance exceeds bountyMaxBalance");
        //tranfer msgSender, currency
        emit BountyBalanceChange(amount, BountyAccountChange.Positive);
    }

    function _removeBountyBalance(uint256 amount) internal {
        LibMembers.MembersStorage storage ms = LibMembers.memberStorage();
        LibERC1155.ERC1155Storage storage es = LibERC1155.erc1155Storage();

        LibMembers.Bounty storage _bounty = LibMembers.getBounty();

        _safeTransferFrom(_bounty.Address, LibDiamond.getContractOwner(), _bounty.CurrencyId, amount, "");
        emit BountyBalanceChange(amount, BountyAccountChange.Negative);
    }

    //permissioned OWNER ONLY
    function _setBountyCurrencyId(uint256 currencyId) internal {
        LibMembers.Bounty storage _bounty = LibMembers.getBounty();

        _bounty.CurrencyId = currencyId;
    }

    function _setBountyMaxBalance(uint256 maxBalance) internal {
        LibMembers.Bounty storage _bounty = LibMembers.getBounty();
        _bounty.MaxBalance = maxBalance;
    }

    function _setBountyAddress(address _bountyAddress) internal {
        require(_bountyAddress != address(0), "Bounty address cannot equal the zero address.");
        LibMembers.Bounty storage _bounty = LibMembers.getBounty();

        _bounty.Address = _bountyAddress;
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
