const { ethers } = require('hardhat')

async function deployExchange(){
    const Exchange = await ethers.getContractFactory('Exchange')
    const exchange = await Exchange.deploy();
}