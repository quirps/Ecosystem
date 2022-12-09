/* global ethers */
/* eslint prefer-const: "off" */

const { getSelectors, FacetCutAction } = require('./libraries/diamond.js')
const { ethers } = require("hardhat");

async function deployFrozenGlobal (diamondAddress) {
  const accounts = await ethers.getSigners()
  const contractOwner = accounts[0]
  let _globalFreezeSelectors;
  // deploy DiamondCutFacet
  const FrozenGlobal = await ethers.getContractFactory('FreezeGlobal')
  const FrozenGlobalFacet = await FrozenGlobal.deploy()
  await FrozenGlobalFacet.deployed()
  console.log("FrozenGlobalFacet address - %s",FrozenGlobalFacet.address)
  console.log('FrozenGlobal deployed:', FrozenGlobalFacet.address)

  
  // deploy facets
  console.log('')
  console.log('Deploying facets')
  const FacetNames = [
    'FreezeGlobal'
  ]
  const cut = []
  for (const FacetName of FacetNames) {
    const Facet = await ethers.getContractFactory(FacetName)
    const facet = await Facet.deploy()
    _globalFreezeSelectors = getSelectors(facet)
    await facet.deployed()
    console.log(`${FacetName} deployed: ${facet.address}`)
    cut.push({
      facetAddress: facet.address,
      action: FacetCutAction.Add,
      functionSelectors: _globalFreezeSelectors
    })
  }


  console.log('')
  console.log('Diamond Cut:', cut)
  const FrozenGlobalCut = await ethers.getContractAt('IFreezeGlobal', diamondAddress)
  // initialization
  let functionCall = FrozenGlobalCut.interface.encodeFunctionData("init",[_globalFreezeSelectors])
  //
  let tx
  let receipt
  const diamondCut = await ethers.getContractAt('IDiamondCut', diamondAddress)

  tx = await diamondCut.diamondCut(cut, FrozenGlobalFacet.address, functionCall)
  console.log('Diamond cut tx: ', tx.hash)
  receipt = await tx.wait()
  if (!receipt.status) {
    throw Error(`Diamond upgrade failed: ${tx.hash}`)
  }
  console.log('Completed diamond cut')
  const diamondLoupeFacet = await ethers.getContractAt('IDiamondLoupe', diamondAddress)
  let _facetAddresses = await diamondLoupeFacet.facetAddresses();
  console.log(3)
  
  }
  exports.deployFrozenGlobal = deployFrozenGlobal;