pragma solidity ^0.8.6;

library LibUtilityAddressManagement{
    bytes32 constant UTILITY_ADDRESS_MANAGEMENT_STORAGE_POSITION = keccak256("diamond.standard.utilityaddressmanagement.storage");
    struct UtilityAddressManagement_Storage{
        address communityFundAddress;
    }

    function utilityaddressmanagementStorage() internal pure returns (UtilityAddressManagement_Storage storage us){
        bytes32 UTILITY_ADDRESS_MANAGEMENT_STORAGE_POSITION = UTILITY_ADDRESS_MANAGEMENT_STORAGE_POSITION;
        assembly{
            us.slot := UTILITY_ADDRESS_MANAGEMENT_STORAGE_POSITION
        }
    }

    
}   