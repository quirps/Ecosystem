pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;


import "./ERC1155Transfer.sol";

contract Members is ERC1155Transfer{
    //history is to save gas on not having to prove every time
    struct MemberRank{
        uint96 timestamp;
        bytes30 rankLabel;
    }
    mapping( address => MemberRank[]) memberRankHistory;
    
    mapping(bytes30 => uint16) rank;
    bytes30[] rankLabels;

    bytes32 memberRankRoot;
    
    function initialization(address _bountyAddress) external {
       bountyAddress = _bountyAddress; 
    }

    function changeRankLabels(bytes30[] memory _oldRankLabels, bytes30[] memory _newRankLabels) external {
        for(uint16 i; i < _oldRankLabels.length; i++){
            uint16 _rank;
            _rank = rank[ _oldRankLabels[ i ] ];
            rank[ _oldRankLabels[ i ] ] = 0;
            rank[ _newRankLabels[ i ] ] = _rank;
        }
    }

    function getUserRankHistory(address user) external view returns (MemberRank[] memory memberHistory_ ){
        memberHistory_ = memberRankHistory[ user ];
    }
    function getUserRankLabel(address user) external view returns (bytes30 rankLabel_) {
        MemberRank[] memory _memberRankHistory = memberRankHistory [ user ];
        rankLabel_ = _memberRankHistory[ _memberRankHistory.length - 1 ].rankLabel;

    }
    function getUserRank(address user) external view returns (uint16 rank_){
        MemberRank[] memory _memberRankHistory = memberRankHistory [ user ];
        bytes30 _rankLabel = _memberRankHistory[ _memberRankHistory.length - 1 ].rankLabel;
        rank_ = rank[ _rankLabel ];
    }
    /**
     * Enable Owner/Moderator priveleged
     * @param _rankLabels rank label to be added or deleted
     * @param _ranks  rank to be given to new label, ignores value on delete
     * @param _delete  true if deleting a rank label, else push new label
     * @param _index index of rank label in storage, needed for delete
     */
    function changeRanks(bytes30[] memory _rankLabels, uint16[] memory _ranks, bool[] memory _delete, uint16[] memory _index) external {
        for(uint16 i; i < _rankLabels.length; i++){
            rank[ _rankLabels [ i ] ] = _delete[ i ] ? _ranks[ i ] : 0;
            if ( _delete [ i ] ) { 
                rankLabels[ _index [i ] ] = rankLabels[ rankLabels.length - 1];
                delete rankLabels[ rankLabels.length - 1 ];
            }
            else{
                rankLabels.push( _rankLabels [ i ] );
            }
        }
    }


    //
    function setMemberRankPermissioned( address[] memory _member, bytes30[] memory _rankLabel ) external{
        for(uint16 i; i < _member.length; i++ ){
            MemberRank memory _memberHistory = MemberRank( uint96( block.timestamp ), _rankLabel[ i ] );
            memberRankHistory[ _member[ i ] ].push( _memberHistory );
        }
    }

    function setMembersRanks( address[] memory _member, MemberRank[] memory _newMemberHistory ) external{
        //multiproof, revert on failed proof
        uint256 bountiesUp;
        uint256 bountiesDown;
        for(uint256 i; i < _member.length; i++ ){
            MemberRank[] memory _memberRankHistory = memberRankHistory [ _member[ i ] ];
            MemberRank memory _memberRank = _memberRankHistory[ _memberRankHistory.length - 1 ];
            if( _newMemberHistory[ i ].timestamp <= _memberRank.timestamp ||
                _newMemberHistory[ i ].rankLabel == _memberRank.rankLabel  ) {
                    continue;
                }
            memberRankHistory[ _member[ i ] ].push( _newMemberHistory[ i ] );
            true ? bountiesUp ++ : bountiesDown--; //fix condition

        }
        //transfer();
        //bounty hook
        /**
         * Should use a specialized version of transfer facet or same version as
         * other? Simpler version would make sense, could do later. For now use
         * base verison.
         */
    }


    /**
     * Bounty Methods 
     */

    //Bounty rate set offline
    //hard cap bounty balance
    
    uint256 bountyCurrencyId;
    uint256 bountyMaxBalance;
    address bountyAddress;
    function addBountyBalance(uint256 amount) external {
        uint256 bountyBalance;
        //get bountyBalance(bountyAddress, bountyCurrencyId)
        uint256 _bountyCurrencyId = bountyCurrencyId;
        address _bountyAddress = bountyAddress;
        uint256 newAmount = bountyBalance + amount;
        require(newAmount <= bountyMaxBalance,"New bounty balance exceeds bountyMaxBalance");
        //tranfer msgSender, currency
    }
    function removeBountyBalance(uint256 amount) external {
        //transfer amount to owner
    }
    //permissioned OWNER ONLY
    function setBountyCurrencyId(uint256 currencyId) external {
        bountyCurrencyId = currencyId;
    }
    function setBountyMaxBalance(uint256 maxBalance) external{
        bountyMaxBalance = maxBalance;
    }
    function setBountyAddress( address _bountyAddress) external{
        require(_bountyAddress != address(0),"Bounty address cannot equal the zero address.");
        bountyAddress = _bountyAddress;
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
  


        struct MerkleProof{
        bytes32 a;
    }

    // param takes in merkle proof
    // rejects on invalid prooof

    function _proveMembership(MerkleProof[] memory proof) internal view{
        // prove
    }
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
