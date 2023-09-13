/**
 * Should deploy relay, upload new versions, deploy new ecosystems
 */
const {ethers} = require('hardhat')
const hre = require('hardhat')


async function registryDeploy(){
    let Registry = await ethers.getContractFactory('DiamondRegistry')
    let registry = await  Registry.deploy()
    await registry.deployed();
    return registry.address
}

async function registryUploadAndDeploy(registryAddress, version){
    let registry = await ethers.getContractAt('DiamondRegistry', registryAddress)
    let versionNumber = version[0];
    let diamondBytecode = (await ethers.getContractFactory('Diamond')).bytecode
    await registry.uploadVersion(...version)
    diamondAddress = await registry.callStatic.deployVersion(versionNumber, diamondBytecode)
    //console.log(diamondAddress)
    await registry.deployVersion(versionNumber, diamondBytecode)
    return diamondAddress
}
if (require.main === module) {
    registryDeploy()
      .then(() => process.exit(0))
      .catch(error => {
        console.error(error)
        process.exit(1)
      })
  }
module.exports = {registryDeploy, registryUploadAndDeploy}