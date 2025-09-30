pragma solidity ^0.8.28;

import "./LibUtilityAddressManagement.sol";

contract UtilityAddressManagement{

    event CommunityFundAddressSet(address);
    function setCommunityFundAddress( address _communityFundAddress) external {
        LibUtilityAddressManagement.UtilityAddressManagement_Storage storage us = LibUtilityAddressManagement.utilityaddressmanagementStorage();
        us.communityFundAddress = _communityFundAddress;
        emit CommunityFundAddressSet( _communityFundAddress );
    }
    function getCommunityFundAddress() external view returns (address communityFundAddress_){
        LibUtilityAddressManagement.UtilityAddressManagement_Storage storage us = LibUtilityAddressManagement.utilityaddressmanagementStorage();
        communityFundAddress_ = us.communityFundAddress;
    }
}