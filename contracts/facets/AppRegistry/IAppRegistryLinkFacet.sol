pragma solidity ^0.8.28;
// Interface remains the same
interface IAppRegistryLinkFacet {
    event AppInstalled(bytes32 indexed eventType, address indexed instanceAddress);
    event AppUninstalled(bytes32 indexed eventType);
    event AppRegistrySet(address indexed registryAddress);
    function setAppRegistryAddress(address registryAddress) external;
    function setInstalledAppFromRegistry(bytes32 eventType, address instanceAddress) external;
    function getTrustedAppRegistry() external view returns (address);
} 