//initAddress can either be an address or string in FacetNames
const {ethers} = require('hardhat')
const { getSelectors, FacetCutAction } = require('./libraries/diamond.js')

async function deployFacet(FacetNames, diamondAddress, initAddress, calldata){
    //deploy erc1155
    const cut = []
    for (const FacetName of FacetNames) {
        const Facet = await ethers.getContractFactory(FacetName)
        const facet = await Facet.deploy()
        await facet.deployed()
        if ( FacetName == initAddress ){
            
            initAddress = facet.address
        }
        console.log(`${FacetName} deployed: ${facet.address}`)
        cut.push({
        facetAddress: facet.address,
        action: FacetCutAction.Add,
        functionSelectors: getSelectors(facet)
        })
    }
    console.log('Diamond Cut:', cut)
    const diamondCut = await ethers.getContractAt('IDiamondCut', diamondAddress)
    let tx
    let receipt
    tx = await diamondCut.diamondCut(cut, initAddress, calldata)
    console.log('Diamond cut tx: ', tx.hash)
    receipt = await tx.wait()
    if (!receipt.status) {
        throw Error(`Diamond upgrade failed: ${tx.hash}`)
    }
    console.log('Completed diamond cut')
        //add erc1155 facet

}

module.exports = {deployFacet}