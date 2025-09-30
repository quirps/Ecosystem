pragma solidity ^0.8.28;

interface IUtilityAddressManagement{
  function setCommunityFundAddress( address _communityFundAddress) external;
  function getCommunityFundAddress() external view returns (address communityFundAddress_);
}