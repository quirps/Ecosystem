const {ethers} = require('hardhat')


export async function erc1155RewardDeploy(){
    const ERC1155Reward = await ethers.getContractFactory('ERC1155Rewards')
    const erc1155Reward = await ERC1155Reward.deploy();
    return erc1155Reward;
}