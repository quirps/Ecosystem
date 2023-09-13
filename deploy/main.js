/**
 * deploys facets & diamondDeploy
 * deploys registryAddress 
 * deploys diamond and cuts facets
 * initializes
 * actions
 * 
 * Meant for backend and testing.
 * New flow required for frontend
 */

const {ethers} = require('hardhat')
const {getSelectors} = require('../scripts/libraries/diamond')

const {preDiamondDeploy}  = require("./preDiamondDeploy")
const {registryDeploy, registryUploadAndDeploy} = require("./registryDeploy")


async function main(facetNames){
    let registryAddress;
    let diamondAddress
    //deploy facets and diamondDeploy contract
    const[diamondDeployAddress, facets] = await preDiamondDeploy(facetNames);
    registryAddress = await registryDeploy();
    
    let version = [
        1,
        diamondDeployAddress,
        [],
        facets
    ]
    diamondAddress = await registryUploadAndDeploy(registryAddress, version)

    const ecosystem = await ethers.getContractAt('Ecosystem',diamondAddress)
     let addresses = await ecosystem.callStatic.facetAddresses()
     
    console.log(3)
}

if (require.main === module) {
    main()
      .then(() => process.exit(0))
      .catch(error => {
        console.error(error)
        process.exit(1)
      })
  }
  //main()
module.exports = {main}