

 


const { ecosystemDeploy } = require('./ecosystem/ecosystemDeploy');

const { saveDeployState, removeDeployState} = require("./attach/attatchments")



import type { EcosystemConfig } from "../types/deploy/userConfig";

const {ethers} = require('hardhat')

async function main(name : string, version : string) { 
  // console.log("Before")
  // await hre.run("fundwallet", {"to" : "0xa4fbDF500D758aDa4Ca6F9a01FA5b3Dc6566800F",
  //                              "amount" : "1000"} )
  // console.log("After")

  //remove previous deploy state 
  removeDeployState();

  //load in test params
  //const { ecosystemConfigData, userConfigData}  = await randomUserConfig(NUM_USERS)
 
  
  //deploy exchange
  //const exchange = await exchangeDeploy();

  //deploy exchange ERC1155Reward  
  //const erc1155ExchangeReward = await erc1155RewardDeploy();
  //deploy Swap 
  //const  swap = await swapDeploy();  
  
  const [owner] = await ethers.getSigners()
  const ecosystemConfig : EcosystemConfig ={name,version,owner}
  const { ecosystems, registry } = await ecosystemDeploy( [ecosystemConfig] )

  //Deploy relay 
  //const { target, relay, paymaster, trustedForwarder } = await relayDeploy()
  //initialize users
 //an error in here from a tx that only occurs once 
//  console.log("starting userConfig")
//   await userConfig(userConfigData, ecosystems, exchange.address, swap.address) 
//   console.log("generate swap orders")

  // const signers : Signer[] = await ethers.getSigners()
  // //create swap orders
  // const token1 = ecosystems[ ecosystemConfigData [ 0 ].name ].address
  // const token2 = ecosystems[ ecosystemConfigData [ 1 ].name ].address
  // //swapOrders 1 has token1 has input, token 2 as output, swapOrders2
  // is the opposite
  // const [swapOrders1, swapOrders2] = await generateSwapOrders( signers.slice(4,18), token1, token2,  swap)
  // console.log("Done")
  // //test swap
  // const testSwap = swapOrders1[ swapOrders1.length - 1]

  // //consume a swap order
  // console.log("Consume token swap order")
  // await consumeSwapOrders( signers[8], testSwap, swap)

  // //eth swap order
  // console.log("begin eth swap consume")
  
  // await ethSwapTest( swap, token1);

  console.log("Finished swap eth consume!")

  //save network deploy state
  const deployStateEntry = {
     Ecosystem : Object.keys(ecosystems).reduce((acc : any , key) => {
                  acc[key] = ecosystems[key].address;
                  return acc; }, {}),
    // MassDXSwap :  swap.address,
    // MassDX : exchange.address, 
     //TrustedForwarder : trustedForwarder.address,
    // Paymaster : paymaster.address,
    // Relay : relay.address, 
     //Target : target.address ,
    // ERC1155Rewards : erc1155ExchangeReward.address,
     Registry : registry.address
  }
  saveDeployState( deployStateEntry )
}



const name = "TestEcosystem"
const version = "0.0.0"

main( name, version)


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
//0x7f277a98a47042Ca8874336a2e20Ab8482942820 Latest REgistry Address