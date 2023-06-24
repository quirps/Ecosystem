pragma solidity ^0.8.6;

library LibMemberRegistry {
    bytes32 constant MemberRegistry_STORAGE_POSITION = keccak256("diamond.standard.MemberRegistry.storage");

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

    struct MemberRegistry_Storage {
        uint96 verificationTime;
        mapping(address => string) addressToUsername;
        mapping(string => address) usernameToAddress;
        mapping(string => Recovery) usernameToRecoveryAddress;
        mapping(address => uint256) nonces;
    }

    function MemberRegistryStorage() internal pure returns (MemberRegistry_Storage storage es) {
        bytes32 MemberRegistry_STORAGE_POSITION = MemberRegistry_STORAGE_POSITION;
        assembly {
            es.slot := MemberRegistry_STORAGE_POSITION
        }
    }
}
