pragma solidity ^0.8.6;

library LibMembers {
    bytes32 constant MEMBER_STORAGE_POSITION = keccak256("diamond.standard.members.storage");
    struct MembersStorage {
        bytes32 MembersMerkleRoot;
        mapping(bytes28 => MemberRank) memberRank;
        mapping(address => bytes8) memberRankPointer;
        uint32 maxRank;
        bytes32 memberRankRoot;
        mapping(uint8 => Bounty) bounty;
    }

    struct Bounty {
        uint256 currencyId;
        uint256 maxBalance;
        address bountyAddress;
        uint256 upRate;
        uint256 downRate;
    }
    //issue with a struct array is can't trivially change struct
    //if add a member to the struct, you'll immedietely ovveride next sequential
    // slot (if of course new struct size is > 32 bytes)
    // can add extra storage slots, but will be more expensive of course

    /**
     * Linked list via mappings can mitigate this issue.
     *  ________            _______          ________
     * |DataA  |           |DataB  |        | DataC  |
     * |LinkerA|   ---->   |LinkerB| ------>| LinkerC|---> ...
     * |_______|           |_______|        |________|
     * Is this cheaper than Struct Buffers? Would need a mappping for
     */
    /**
     * memberRankPointer is the key for memberRankBlock, which retrieves
     * the member's latest MemberRank. The previous block can be
     * 
     */
    struct MerkleLeaf {
        address memberAddress;
        MemberRank memberRank;
    }

    struct MemberRank{
        uint48 timestamp;
        uint32 rank;
    }
   

    function memberStorage() internal pure returns (MembersStorage storage ms_) {
        bytes32 position = MEMBER_STORAGE_POSITION;
        assembly {
            ms_.slot := position
        }
    }

    function addUserBlock(MemberRank memory _memberRank, address user) internal {
        bytes8 maxIndex = memberStorage().memberRankPointer[ user ];
        bytes8 newMax = bytes8( uint64(maxIndex) + 1 );
        bytes28 newKey = bytes28( abi.encodePacked( newMax, user) );
        memberStorage().memberRank[ newKey ]  = _memberRank;

    }
    
    function getBlockHistoryNumber(bytes28 key) external returns(bytes8 number_){
        number_ = bytes8( key );
    }

    //Key management
    //================================================
    function createInitialKey(address user, bytes8 index) internal returns (bytes28 keyInit_){
        keyInit_ = abi.encodePacked( index, user);
    }
    function decrement(bytes28 self) external returns( bytes28 decrementedKey_ ){
        decrementedKey_ = abi.encodePacked( uint64( bytes8( self ) ) - 1, self << 64 );
    }
    function increment(bytes28 self) external returns( bytes28 incrementedKey_ ){
        incrementedKey_ = abi.encodePacked( uint64( bytes8( self ) ) + 1, self << 64 );
    }
    function decrement(bytes8 self) internal returns( bytes8 decrementMaxIndex_ ){
        decrementMaxIndex_ = bytes8( uint64( self ) - 1 );
    }
    function increment(bytes8 self) internal returns( bytes8 incrementMaxIndex_ ){
        incrementMaxIndex_ = bytes8( uint64( self ) + 1 );
    }
    //retrieve history batch 

    function getHistoryBatch(address[] users, bytes28[] keys) external{

    }
  
    /**
     * Retrieves the user's rank history, starting from their current rank and going backwards 
     * amount depth or before if key == type (uint192).min
     * @param user user whos rank history we're interested in
     * @param depth the amount of historical blocks we'd like to retrieve
     */
    function rankHistory(address user, uint64 depth) internal view returns (MemberRank[] memory rankHistory_){
        (uint192 _key,uint64 _length) = ( memberStorage().memberRankPointer[ user ].key, 
                                          memberStorage().memberRankPointer[ user ].length );
        rankHistory_ = new MemberRank[](depth);
        for( uint64 i; i < _length; i++){
            if( _key == type( uint192 ).min ){
                break;
            }
            MemberRankBlock memory _memberRankBlock = memberStorage().memberRankBlock[ _key ];
            rankHistory_[i] =  _memberRankBlock.memberRank ;
            _key = _memberRankBlock.key;

        }
    }

    function getBounty() internal view returns (Bounty storage bounty_){
        bounty_ = memberStorage().bounty[0];
    }
}
