/* global ethers */
const { ethers } = require("hardhat");

const FacetCutAction = { Add: 0, Replace: 1, Remove: 2 }

// get function selectors from ABI
function getSelectors (contract) {
  const signatures = Object.keys(contract.interface.functions)
  const selectors = signatures.reduce((acc, val) => {
    if (val !== 'init(bytes)') {
      acc.push(contract.interface.getSighash(val))
    }
    return acc
  }, [])
  
  return selectors
}

// get function selector from function signature
function getSelector (func) {
  const abiInterface = new ethers.utils.Interface([func])
  return abiInterface.getSighash(ethers.utils.Fragment.from(func))
}

// used with getSelectors to remove selectors from an array of selectors
// functionNames argument is an array of function signatures
function remove (functionNames) {
  const selectors = this.filter((v) => {
    for (const functionName of functionNames) {
      if (v === this.contract.interface.getSighash(functionName)) {
        return false
      }
    }
    return true
  })
  selectors.contract = this.contract
  selectors.remove = this.remove
  selectors.get = this.get
  return selectors
}

// used with getSelectors to get selectors from an array of selectors
// functionNames argument is an array of function signatures
function get (functionNames) {
  const selectors = this.filter((v) => {
    for (const functionName of functionNames) {
      if (v === this.contract.interface.getSighash(functionName)) {
        return true
      }
    }
    return false
  })
  selectors.contract = this.contract
  selectors.remove = this.remove
  selectors.get = this.get
  return selectors
}

// remove selectors using an array of signatures
function removeSelectors (selectors, signatures) {
  const iface = new ethers.utils.Interface(signatures.map(v => 'function ' + v))
  const removeSelectors = signatures.map(v => iface.getSighash(v))
  selectors = selectors.filter(v => !removeSelectors.includes(v))
  return selectors
}

// find a particular address position in the return value of diamondLoupeFacet.facets()
function findAddressPositionInFacets (facetAddress, facets) {
  for (let i = 0; i < facets.length; i++) {
    if (facets[i].facetAddress === facetAddress) {
      return i
    }
  }
}

async function selectorCollision(facets) {
  let seen = new Map(); // Maps selectors to the facet name where they were first seen

  for (const facet of facets) {
      const { name: facetName, facetCut: { functionSelectors } } = facet;

      for (const selector of functionSelectors) {
          if (seen.has(selector)) {
              // Retrieve the original facet and function signatures for the colliding selector
              const originalFacetName = seen.get(selector);
              const originalSignature = await getFunctionSignature(originalFacetName, selector);
              const collidingSignature = await getFunctionSignature(facetName, selector);

              return [originalFacetName, facetName, selector, `Collision between ${originalSignature} and ${collidingSignature}`];
          }

          seen.set(selector, facetName);
      }
  }

  return null; // No collisions found
}

async function getFunctionSignature(facetName, selector) {
  // Retrieve the ABI of the facet
  const facetABI = await ethers.getContractFactory(facetName);
  const iface = facetABI.interface;

  // Match the selector to the function signature
  for (const [signature, sigSelector] of Object.entries(iface.functions)) {
      if (iface.getSighash(signature) === selector) {
          return signature;
      }
  }

  return "Unknown function"; // In case the selector isn't found (shouldn't happen)
}



exports.getSelectors = getSelectors
exports.getSelector = getSelector
exports.FacetCutAction = FacetCutAction
exports.remove = remove
exports.removeSelectors = removeSelectors
exports.findAddressPositionInFacets = findAddressPositionInFacets
exports.selectorCollision = selectorCollision
