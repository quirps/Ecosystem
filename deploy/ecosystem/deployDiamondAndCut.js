/* global ethers */
/* eslint prefer-const: "off" */

const {
    FacetCutAction
} = require('../libraries/diamond.js')
const {
    ethers
} = require("hardhat");


async function diamondDeployAndCut(facets) {
    
    // deploy Diamond
    const Diamond = await ethers.getContractFactory('Diamond')
    const diamond = await Diamond.deploy( facets[0][0])
    await diamond.deployed()
    console.log('Diamond deployed:', diamond.address)

    const diamondInit = await ethers.getContractAt('DiamondInit',facets[1][0])
    

    const cut = []
    for (const facet of facets) {
        if(facet[2] == "DiamondCutFacet"){
            continue
        }
        cut.push({
            facetAddress: facet[0],
            action: FacetCutAction.Add,
            functionSelectors: facet[1]
        })
    }


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

    console.log(3)
    return [diamond.address, facets]
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
    diamondDeployAndCut()
        .then(() => process.exit(0))
        .catch(error => {
            console.error(error)
            process.exit(1)
        })
}

exports.diamondDeployAndCut = diamondDeployAndCut