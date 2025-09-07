// deploymentConfig.js
// Use bytes32 for version numbers, e.g., ethers.utils.formatBytes32String("1.0.0")
const VERSION_NUMBER = "1.0.0"
const LATEST_VERSION = ethers.utils.formatBytes32String(VERSION_NUMBER);
const V1 = [
  'DiamondCutFacet', 'EventFacet','DiamondInit', 'DiamondLoupeFacet', 'ERC1155Ecosystem', 'ERC1155Transfer','ERC1155ReceiverEcosystem','ERC20Ecosystem', 'MemberRegistry',
  'MembershipLevels', 'Moderator', 'OwnershipFacet', 'StakeConfig','ERC2981','TicketCreate','AppRegistryLinkFacet','TieredPermission'
]
const chainlinkConfig = {vrfCoordinator: "0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625", // <-- Paste from Chainlink Docs
  vrfSubscriptionId: 0, // <-- Set this to 0, we'll create/set it in the configure script
  vrfKeyHash: "0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae", // <-- Paste from Chainlink Docs
  vrfCallbackGasLimit: 500000, // <-- Your chosen limit (e.g., 500k gas)
  linkToken: "0x779877A7B0D9E8603169DdbD7836e478b4624789", // <-- Paste from Chainlink Docs (for funding reference)}
}
const networks = ['localhost','sepolia','optimism']
const config = {
  networks,
  VERSION_NUMBER,
  localhost: {
    versionToDeploy: LATEST_VERSION,
    // Add DiamondLoupeFacet, potentially OwnershipFacet by default
    facets:  V1,
    // Set the desired owner for the new Diamond instance
    diamondOwner: null, // Set to deployer by default, or specify an address
    ...chainlinkConfig,
  },
  hardhat : {
    versionToDeploy: LATEST_VERSION,
    // Add DiamondLoupeFacet, potentially OwnershipFacet by default
    facets: V1,
    // Set the desired owner for the new Diamond instance
    diamondOwner: null, // Set to deployer by default, or specify an address
    ...chainlinkConfig,
  },
  sepolia: {
    versionToDeploy: LATEST_VERSION,
    facets:  V1,
    diamondOwner: null, // Specify owner address for Sepolia
    
    blockConfirmations: 6, // Example confirmations for Sepolia
    // --- VRF V2 CONFIGURATION for SEPOLIA ---
    ...chainlinkConfig,
  },
  // Add other networks like mainnet
};



module.exports  = config;