// utils/deploy-helpers.js
const { ethers } = require("hardhat");

// Function to get facet selectors
// Remove selectors inherited from interfaces like IDiamondCut, IDiamondLoupe, IERC173, IERC165
function getSelectors(contract) {
  const signatures = Object.keys(contract.interface.functions);
  const selectors = signatures.reduce((acc, val) => {
    // Filter out common interface functions and constructor/receive/fallback
    if (
      !val.includes("supportsInterface(bytes4)") && // IERC165
      !val.includes("owner()") && // IERC173
      !val.includes("transferOwnership(address)") && // IERC173
      !val.includes("diamondCut((address,uint8,bytes4[])[],address,bytes)") && // IDiamondCut
      !val.includes("facetAddress(bytes4)") && // IDiamondLoupe
      !val.includes("facetAddresses()") && // IDiamondLoupe
      !val.includes("facetFunctionSelectors(address)") && // IDiamondLoupe
      !val.includes("facets()") && // IDiamondLoupe
      !val.includes("()") // Filter out constructor/receive/fallback if present as keys
    ) {
      acc.push(contract.interface.getSighash(val));
    }
    return acc;
  }, []);

  // Ensure unique selectors
  return [...new Set(selectors)];
}

// Function to create FacetCut struct array
async function createFacetCuts(facetNames, deployments) {
  const facetCuts = [];
  console.log("Creating Facet Cuts for:", facetNames);
  for (const facetName of facetNames) {
    console.log(` Processing facet: ${facetName}`);
    const facetDeployment = await deployments.get(facetName);
    const facetContract = await ethers.getContractAt(
      facetName,
      facetDeployment.address
    );
    const selectors = getSelectors(facetContract);
    if (selectors.length === 0) {
      console.warn(`  WARNING: No unique function selectors found for ${facetName}. Skipping.`);
      continue;
    }
    console.log(`   Selectors: ${selectors}`);
    facetCuts.push({
      facetAddress: facetDeployment.address,
      action: 0, // FacetCutAction.Add
      functionSelectors: selectors,
    });
  }
  return facetCuts;
}

module.exports = {
  getSelectors,
  createFacetCuts,
};