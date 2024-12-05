const {ethers} = require('hardhat')



async function main(){
    const Ecosystem = await ethers.getContractFactory("Ecosystem")
    const ecosystem = await Ecosystem.deploy()
    console.log(3)
}

main()