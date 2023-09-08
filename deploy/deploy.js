//Deploys current version
const hre = require('hardhat')
const {
    getSelectors
} = require("../scripts/libraries/diamond")
const {FACETS } = require('./constants')
//Import a class for registry
// uint240 versionNumber,
// address diamondAddress,
// uint256[][] memory optimizationMaps,
// Facet[] memory facets
//Likely import this from config

async function deploy() {
    let diamondCutFacetAddress;
    let facets = []
    let deployedStatuses = [];
    for (let facetName of FACETS) {
        let Facet = await hre.ethers.getContractFactory(facetName);
        const facet = await Facet.deploy()
        deployedStatuses.push(facet.deployed());
        if (facetName = "DiamondCutFacet") {
            diamondCutFacetAddress = facet.address;
        }
        facets.push([
            facet.address, getSelectors(facet)
        ])
    }
    await Promise.all(deployedStatuses)

    const Diamond = await hre.ethers.getContractFactory('Diamond');

    const DiamondDeploy = await hre.ethers.getContractFactory('DiamondDeploy');
    const diamondDeploy = await DiamondDeploy.deploy(Diamond.bytecode, diamondCutFacetAddress)
    await diamondDeploy.deployed();

    return [diamondDeploy.address, facets]
}

deploy()