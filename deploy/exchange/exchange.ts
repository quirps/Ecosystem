const { ethers } = require('hardhat')

export async function exchangeDeploy() : Promise<any>{
    const Exchange = await ethers.getContractFactory('MassDX')
    const exchange = await Exchange.deploy(ethers.constants.AddressZero);
    console.log("Exchange deployed successfully")
    return exchange
}

