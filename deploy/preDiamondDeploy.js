//Deploys current version

const {
    ethers
} = require('hardhat')
const {
    getSelectors,
    selectorCollsion
} = require("./libraries/diamond")
const {
    FACETS
} = require('./constants')
//Import a class for registry
// uint240 versionNumber,
// address diamondAddress,
// uint256[][] memory optimizationMaps,
// Facet[] memory facets
//Likely import this from config


///need to mesh diamond deploy here with registry deploy
async function preDiamondDeploy(facetNames) {
    let diamondCutFacetAddress;
    let erc1155TransferAddress;
    const facets = []
    const deployedStatuses = [];
    for (let facetName of facetNames || FACETS) {

        console.log(facetName)
        const Facet = await ethers.getContractFactory(facetName);
        const facet = await Facet.deploy()

        deployedStatuses.push(facet.deployed());
        if (facetName == "DiamondCutFacet") {
            diamondCutFacetAddress = facet.address;
        }
        if (facetName == "ERC1155Transfer") {
            erc1155TransferAddress = facet.address;
        }
        facets.push([
            facet.address, getSelectors(facet), facetName
        ])
    }
    await Promise.all(deployedStatuses)

    const collision = selectorCollsion(facets)
    if (collision) {
        throw Error(`Collsion detected at facet ${collision[0]} and facet ${collision[1]} with selector ${collision[2]} \n `)
    }
    const Diamond = await hre.ethers.getContractFactory('Diamond');

    const DiamondDeploy = await hre.ethers.getContractFactory('DiamondDeploy');
    const diamondDeploy = await DiamondDeploy.deploy(Diamond.bytecode, diamondCutFacetAddress)
    await diamondDeploy.deployed();

    return [diamondDeploy.address, facets]
}

if (require.main === module) {
    preDiamondDeploy()
        .then(() => process.exit(0))
        .catch(error => {
            console.error(error)
            process.exit(1)
        })
}
module.exports = {
    preDiamondDeploy
}