pragma solidity ^0.8.6;

import "../../libraries/utils/Incrementer.sol"; 

/**
    user level history keys are designed to be unique by following the program of
    using 8 bytes for the total history length ~1E19 for the highest order 8 bytes 
    and the lowest order 20 bytes for their address (28 byte total)

    Why use a key when can just use uint96 for level history max index?
 */
library LibMemberLevel {
    using Incrementer for bytes28;
    using Incrementer for bytes8;
    bytes32 constant MEMBER_STORAGE_POSITION = keccak256("diamond.standard.members.storage");
    struct MemberLevelStorage {
        mapping( address => MemberLevel ) memberLevel; // level history 
        bytes32 merkleRoot;
    }

    struct Leaf {
        address memberAddress;
        uint32 level;
        uint32 timestamp;
    }

    struct MemberLevel{
        uint32 timestamp;
        uint32 level;
    }
    
    type level is uint32;

    function memberLevelStorage() internal pure returns (MemberLevelStorage storage ms_) { 
        bytes32 position = MEMBER_STORAGE_POSITION;
        assembly {
            ms_.slot := position
        }
    }

    function permissionedChangeLevel( uint32 _level, address member) internal {
        MemberLevelStorage storage ms = memberLevelStorage();
        ms.memberLevel[ member ] = MemberLevel( uint32( block.timestamp ), _level ); 
    }
  
 
}
