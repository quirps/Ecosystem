/* global ethers */
/* eslint prefer-const: "off" */

const { getSelectors, FacetCutAction } = require('./libraries/diamond.js')
const { ethers } = require("hardhat");

async function deployFrozenOwner (diamondAddress) {
  const accounts = await ethers.getSigners()
  const contractOwner = accounts[0]

  // deploy DiamondCutFacet
  const FrozenOwner = await ethers.getContractFactory('FreezeOwner')
  const frozenOwnerFacet = await FrozenOwner.deploy()
  await frozenOwnerFacet.deployed()
  console.log('FrozenOwner deployed:', frozenOwnerFacet.address)

  
  // deploy facets
  console.log('')
  console.log('Deploying facets')
  const FacetNames = [
    'FreezeOwner'
  ]
  const cut = []
  for (const FacetName of FacetNames) {
    const Facet = await ethers.getContractFactory(FacetName)
    const facet = await Facet.deploy()
    await facet.deployed()
    console.log(`${FacetName} deployed: ${facet.address}`)
    cut.push({
      facetAddress: facet.address,
      action: FacetCutAction.Add,
      functionSelectors: getSelectors(facet)
    })
  }


  console.log('')
  console.log('Diamond Cut:', cut)
  const frozenOwnerCut = await ethers.getContractAt('IFreezeOwner', diamondAddress)
  // initialization
  //let functionCall = frozenOwnerCut.interface.encodeFunctionData("init",[429,"0xb79872DC1E960B7C6B9b5E832dD55D9c2bf653cb","0xDAFEA492D9c6733ae3d56b7Ed1ADB60692c98Bc5","0xb79872DC1E960B7C6B9b5E832dD55D9c2bf653cb"])
  //
  let tx
  let receipt
  const diamondCut = await ethers.getContractAt('IDiamondCut', diamondAddress)

  tx = await diamondCut.diamondCut(cut, ethers.constants.AddressZero, '0x')
  console.log('Diamond cut tx: ', tx.hash)
  receipt = await tx.wait()
  if (!receipt.status) {
    throw Error(`Diamond upgrade failed: ${tx.hash}`)
  }
  console.log('Completed diamond cut')
  
  
  }
  exports.deployFrozenOwner = deployFrozenOwner;