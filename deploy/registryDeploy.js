/**
 * Should deploy relay, upload new versions, deploy new ecosystems
 */
const {ethers} = require('hardhat')


async function registerDeploy(){
    const Register = await ethers.getContractFactory('Register')
    const register = await  Register.deploy()
    await register.deployed();

}

async function registerUploadAndDeploy(register, args){

    return diamondAddress
}
if (require.main === module) {
    registerDeploy()
      .then(() => process.exit(0))
      .catch(error => {
        console.error(error)
        process.exit(1)
      })
  }
module.exports = {registerDeploy}