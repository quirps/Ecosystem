pragma solidity ^0.8.6;

library LibMemberRegistry {
    bytes32 constant MEMBER_REGISTRY_STORAGE_POSITION = keccak256("diamond.standard.MemberRegistry.storage");

    struct Recovery {
        address userNewAddress;
        uint32 recoveryTimestamp; //times after this timestamp allow for the user to
        address stakerAddress;
        uint256 stakedAmount;
        //permenantely change.
    }
    struct SignatureVerfication {
        uint256 domain;
        uint256 nonce;
    }
    enum RecoveryStatus {
        Initiated,
        Finalized,
        Cancelled
    }
    struct Leaf {
        string username;
        address userAddress;
    }

    struct MemberRegistryStorage {
        mapping(address => string) addressToUsername;
        mapping(string => address) usernameToAddress;
        mapping(string => Recovery) usernameToRecoveryAddress;
        mapping(address => uint256) nonces;  
        mapping( string => uint256) userSpecificRecoveryStake;
        bytes32 registryMerkleRoot;
        uint32 registryMerkleRootTimestamp;
        uint256 defaultRecoveryStake;
    }    
   
    function memberRegistryStorage() internal pure returns (MemberRegistryStorage storage es) {
        bytes32 storagePosition = MEMBER_REGISTRY_STORAGE_POSITION;
        assembly {
            es.slot := storagePosition 
        }
    }
}
