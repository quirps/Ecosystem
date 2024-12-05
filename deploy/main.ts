


const VERSION : string = "0.0.0";
const ECOSYSTEM_NAME : string = "TEST";

const {ecosystemDeploy} = require('./ecosystem/ecosystemDeploy')
async function main( ) {
  


  const  { ecosystems }  = await ecosystemDeploy(VERSION, ECOSYSTEM_NAME)
  //deploy exchange

  
  console.log("Done")
}
  

main()
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