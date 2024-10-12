pragma solidity ^0.8.0;



library LibOwnership {
bytes32 constant OWNERSHIP_STORAGE_POSITION = keccak256("diamond.ownership.storage");
struct OwnershipStorage{
    address ecosystemOwner;
}

function ownershipStorage() internal pure returns (OwnershipStorage storage os) {
        bytes32 position = OWNERSHIP_STORAGE_POSITION;
        assembly {
            os.slot := position 
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function _setEcosystemOwner(address _newEcosystemOwner) internal {
        OwnershipStorage storage os = ownershipStorage();
        address previousOwner = os.ecosystemOwner;
        os.ecosystemOwner = _newEcosystemOwner;
        emit OwnershipTransferred(previousOwner, _newEcosystemOwner);
    }

    function _ecosystemOwner() internal view returns (address ecosystemOwner_) {
        ecosystemOwner_ = ownershipStorage().ecosystemOwner;
    }

    
    
} 