const {ethers} = require('hardhat')

//import type {Swap, Order } from "../../types/ethers-contracts/swap/Swap"

export async function swapDeploy() : Promise<any>{
    const SwapDeploy = await ethers.getContractFactory('Swap');
    const swapDeploy = await SwapDeploy.deploy();
    return  swapDeploy ;
    console.log("Swap and IPO deployed");
} 


//generate swap orders for a particular ecosystem for a set of users
/**
 * want to create a set of swaps within a given range. an ecosystem 
 * token and ether
 */
export async function swapOrderGenerate() {
    
}


