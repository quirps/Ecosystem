pragma solidity ^0.8.6;

import "../../libraries/utils/Incrementer.sol"; 

/**
    user rank history keys are designed to be unique by following the program of
    using 8 bytes for the total history length ~1E19 for the highest order 8 bytes 
    and the lowest order 20 bytes for their address (28 byte total)

    Why use a key when can just use uint96 for rank history max index?
 */
library LibMembers {
    using Incrementer for bytes28;
    using Incrementer for bytes8;
    bytes32 constant MEMBER_STORAGE_POSITION = keccak256("diamond.standard.members.storage");
    struct MembersStorage {
        mapping( address => mapping(uint96 => MemberRank) ) memberRank; // rank history 
        mapping(address => uint96) memberRankHistoryMaxIndex;
        uint256 recoveryNonce;
        uint32 maxRank;
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
    struct Leaf {
        address memberAddress;
        MemberRank memberRank;
    }

    struct MemberRank{
        uint32 timestamp;
        uint32 rank;
    }
    
    type rank is uint32;

    function memberStorage() internal pure returns (MembersStorage storage ms_) {
        bytes32 position = MEMBER_STORAGE_POSITION;
        assembly {
            ms_.slot := position
        }
    }

    function addUserBlock(MemberRank memory _memberRank, address user) internal {
        uint96 maxIndex = memberStorage().memberRankHistoryMaxIndex[ user ];
        uint96 newMaxIndex = maxIndex + 1;

        memberStorage().memberRank[ user ][ newMaxIndex]  = _memberRank;
        memberStorage().memberRankHistoryMaxIndex[ user ]  = newMaxIndex;

    }

    function permissionedChangeRank( Leaf memory _leaf) internal {
        MembersStorage storage ms = memberStorage();
        
    }
  
    /**
     * Retrieves the user's rank history, starting from their current rank and going backwards 
     * amount depth or before if key == type (uint192).min
     * @param user user whos rank history we're interested in
     * @param depth the amount of historical blocks we'd like to retrieve
     */
    function rankHistory(address user, uint96 depth) internal view returns (MemberRank[] memory rankHistory_){
        uint96 _maxIndex =  memberStorage().memberRankHistoryMaxIndex[ user ];
        rankHistory_ = new MemberRank[](depth);
        for( uint96 i; i < depth; i++){
            if( _maxIndex - i < 0 ){
                break;
            }
            rankHistory_[i] =  memberStorage().memberRank[ user ][ _maxIndex - i ];
        }
    }
}
