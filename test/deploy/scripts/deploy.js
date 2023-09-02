/* global ethers */
/* eslint prefer-const: "off" */

const { Signer } = require('ethers');
const hre = require("hardhat");
const { getSelectors, FacetCutAction } = require('../libraries/diamond.js')
const { ethers } = require("hardhat");

async function deployDiamond () {
  const accounts = await ethers.getSigners()
  const contractOwner = accounts[0]

  // deploy DiamondCutFacet
  const DiamondCutFacet = await ethers.getContractFactory('DiamondCutFacet')
  const diamondCutFacet = await DiamondCutFacet.deploy()
  await diamondCutFacet.deployed()
  console.log('DiamondCutFacet deployed:', diamondCutFacet.address)

  //diamond bytecode
  const Diamond= await ethers.getContractFactory('Diamond')
  const diamonds = await Diamond.deploy(accounts[0].address, diamondCutFacet.address);
  const diamondBytecode =Diamond.bytecode 

  //deploy DiamondDeploy 
  const DiamondDeploy = await ethers.getContractFactory('DiamondDeploy')
  const diamondDeploy = await DiamondDeploy.deploy(diamondBytecode, diamondCutFacet.address)

  //await diamondDeploy.deploy(diamondBytecode);
  const diamondAddress = await diamondDeploy.callStatic.deploy(diamondBytecode);
  await diamondDeploy.deploy(diamondBytecode);

  console.log('Diamond deployed:', diamondAddress)

  // deploy Diamond
  const diamond = await ethers.getContractAt('Diamond',diamondAddress)
  console.log("Diamond Attatched")

  // deploy DiamondInit
  // DiamondInit provides a function that is called when the diamond is upgraded to initialize state variables
  // Read about how the diamondCut function works here: https://eips.ethereum.org/EIPS/eip-2535#addingreplacingremoving-functions
  const DiamondInit = await ethers.getContractFactory('DiamondInit')
  const diamondInit = await DiamondInit.deploy()
  await diamondInit.deployed()
  console.log('DiamondInit deployed:', diamondInit.address)

  // deploy facets
  console.log('')
  console.log('Deploying facets')
  const FacetNames = [
    'DiamondLoupeFacet',
    'OwnershipFacet'
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

  // upgrade diamond with facets
  console.log('')
  console.log('Diamond Cut:', cut)
  const diamondCut = await ethers.getContractAt('IDiamondCut', diamond.address)
  let tx
  let receipt
  // call to init function
  let functionCall = diamondInit.interface.encodeFunctionData('init')
  tx = await diamondCut.diamondCut(cut, diamondInit.address, functionCall)
  console.log('Diamond cut tx: ', tx.hash)
  receipt = await tx.wait()
  if (!receipt.status) {
    throw Error(`Diamond upgrade failed: ${tx.hash}`)
  }
  console.log('Completed diamond cut')
  const diamondLoupeFacet = await ethers.getContractAt('IDiamondLoupe', diamond.address)
let _facetAddresses = await diamondLoupeFacet.facetAddresses();
  return diamond.address
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
  deployDiamond()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error)
      process.exit(1)
    })
}

exports.deployDiamond = deployDiamond
