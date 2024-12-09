

 


const { ecosystemDeploy } = require('./ecosystem/ecosystemDeploy');
const { exchangeDeploy } = require('./exchange/exchange');
const { erc1155RewardDeploy } = require('./ERC1155Reward/ERC1155Reward');
const { swapDeploy } = require('./swap/swapDeploy');
const { userConfig } = require("./userConfig/config");

import {randomUserConfig, NUM_USERS} from "./configParams"

import type { UserConfig } from "../types/deploy/userConfig";

import type { EcosystemConfig } from "../types/deploy/userConfig";

const {ethers} = require('hardhat')

async function main() { 
  //load in test params
  const { ecosystemConfigData, userConfigData}  = await randomUserConfig(NUM_USERS)
  
  //deploy exchange
  const exchange = await exchangeDeploy();

  //deploy exchange ERC1155Reward  
  const erc1155ExchangeReward = await erc1155RewardDeploy();
  //deploy Swap 
  const  swap = await swapDeploy();  
  
  const ecosystems = await ecosystemDeploy( ecosystemConfigData )

  
 //initialize users
 //an error in here from a tx that only occurs once 
  userConfig(userConfigData, ecosystems, exchange.address, swap.address) 

  //create swap orders
  swapGenerate(  )
  console.log("Done")
}



main( )


if (require.main === module) {
  // main("", false)
  //   .then(() => process.exit(0))
  //   .catch(error => {
  //     console.error(error)
  //     process.exit(1)
  //   })
}

/**
 * What's done: 
 * Facet Deployment
 * Registry Deployment 
 * DiamondDeploy Deployment 
 * 
 * Successful Ecosystem Deployment from registry. 
 * 
 * Next? 
 *  Deploy Exchange
 *  Generate User Config
 *    Tokens
 *    Membership Levels
 *    Tickets
 *    Swap Orders
 *  Generate Swap Orders
 * 
 *    
 *    
 */