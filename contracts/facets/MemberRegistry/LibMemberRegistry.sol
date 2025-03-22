pragma solidity ^0.8.6;

library LibMemberRegistry {
    bytes32 constant MEMBER_REGISTRY_STORAGE_POSITION = keccak256("diamond.standard.MemberRegistry.storage");

    struct Recovery {
        address userNewAddress;
        uint96 recoveryTimestamp; //times after this timestamp allow for the user to
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
        bytes32 registryMerkleRoot;
    }    
   
    function memberRegistryStorage() internal pure returns (MemberRegistryStorage storage es) {
        bytes32 storagePosition = MEMBER_REGISTRY_STORAGE_POSITION;
        assembly {
            es.slot := storagePosition 
        }
    }
}
