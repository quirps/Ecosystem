// deploymentConfig.js
// Use bytes32 for version numbers, e.g., ethers.utils.formatBytes32String("1.0.0")

const LATEST_VERSION = ethers.utils.formatBytes32String("1.0.0");

const config = {
  localhost: {
    versionToDeploy: LATEST_VERSION,
    // Add DiamondLoupeFacet, potentially OwnershipFacet by default
    facets:  [
        'DiamondCutFacet', 'DiamondInit', 'DiamondLoupeFacet', 'ERC1155Ecosystem', 'ERC1155Transfer','ERC1155ReceiverEcosystem','ERC20Ecosystem', 'MemberRegistry',
        'Members', 'Moderator', 'OwnershipFacet', 'EventFactory', 'Stake','ERC2981','TicketCreate',
    ],
    // Set the desired owner for the new Diamond instance
    diamondOwner: null, // Set to deployer by default, or specify an address
  },
  sepolia: {
    versionToDeploy: LATEST_VERSION,
    facets: [
      "DiamondLoupeFacet",
      "OwnershipFacet",
      "MyFeature1Facet",
      "MyFeature2Facet",
    ],
    diamondOwner: "0x...", // Specify owner address for Sepolia
  },
  // Add other networks like mainnet
};

module.exports = config;