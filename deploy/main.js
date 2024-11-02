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

const {
  ethers
} = require('hardhat')
const {
  getSelectors
} = require('../scripts/libraries/diamond')

const {
  preDiamondDeploy
} = require("./preDiamondDeploy")
const {
  diamondDeployAndCut
} = require("./deployDiamondAndCut")
const {
  registryDeploy,
  registryUploadAndDeploy
} = require("./registryDeploy")


async function main(facetNames, registryOn) {
  let registryAddress;
  let diamondAddress
  //deploy facets and diamondDeploy contract
  const [diamondDeployAddress, facets] = await preDiamondDeploy(facetNames);
  if (registryOn) {
    registryAddress = await registryDeploy();
    let version = [
      1,
      diamondDeployAddress,
      [],
      facets.slice(1)
    ]
    diamondAddress = await registryUploadAndDeploy(registryAddress, version)
  } else {
    diamondAddress = await diamondDeployAndCut(facets)
  }
  const ecosystem = await ethers.getContractAt('Ecosystem', diamondAddress)
  console.log("finished")
  return ecosystem


}



if (require.main === module) {
  main("", false)
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error)
      process.exit(1)
    })
}
//main()
module.exports = {
  main
}