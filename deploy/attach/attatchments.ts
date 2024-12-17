/**
 * Exposes deployed contracts at their respective address and prepared txs. 
 * Useful for running scripts after long deployment is done (60 seconds at time of writing)
 */
const {ethers} = require('hardhat')
const fs = require('fs')
const DEPLOY_STATE_PATH = "./deployState.json"

export async function Ecosystems(){
    const contractName = "Ecosystem"
    const addresses = fetchAddress( contractName )
    const ecosystemsPromises = []
    for( let address of addresses){
        ecosystemsPromises.push( ethers.getContractAt("Ecosystem", address) )
    }
    return await Promise.all ( ecosystemsPromises ) ;
}

export async function Swap(){
    const contractName = "MassDXSwap"
    const address = fetchAddress( contractName )
    return await ethers.getContractAt( contractName, address)
}

export async function Exchange(){
    const contractName = "MassDX"
    const address = fetchAddress( contractName )
    return await ethers.getContractAt( contractName, address)
}
export async function ERC1155Rewards(){
    const contractName = "ERC1155Rewards"
    const address = fetchAddress( contractName )
    return await ethers.getContractAt( contractName, address)
}
export async function Registry(){
    const contractName = "EcosystemRegistry"
    const address = fetchAddress( contractName )
    return await ethers.getContractAt( contractName, address)
}


export async function TrustedForwarder(){
    const contractName = "TrustedForwarder"
    const address = fetchAddress( contractName )
    return await ethers.getContractAt( contractName, address)
}
export async function Paymaster(){
    const contractName = "Paymaster"
    const address = fetchAddress( contractName )
    return await ethers.getContractAt( contractName, address)
}
export async function Relay(){
    const contractName = "Relay"
    const address = fetchAddress( contractName )
    return await ethers.getContractAt( contractName, address)
}

export async function Target(){ 
    const contractName = "Target"
    const address = fetchAddress( contractName )
    return await ethers.getContractAt( contractName, address)
}

function fetchAddress( contractName : string ) : string[] | string {
    const deployState= JSON.parse( fs.readFileSync( DEPLOY_STATE_PATH, 'utf8') ) 
    const address = deployState[ contractName ]
    if ( address === undefined){
        throw Error("Contract name not deployed.")
    }
    return address
}

export function saveDeployState( deployState : object){
    const stringifiedDeployState = JSON.stringify( deployState )
    fs.writeFileSync(DEPLOY_STATE_PATH, stringifiedDeployState)

    console.log("Deploy state saved!")
}

export function removeDeployState(){
     // Check if the file exists
     if (fs.existsSync(DEPLOY_STATE_PATH)) {
        // If it exists, delete the file
        fs.unlinkSync(DEPLOY_STATE_PATH);
        console.log(`File at ${DEPLOY_STATE_PATH} has been deleted.`);
    } else {
        console.log(`File at ${DEPLOY_STATE_PATH} does not exist.`);
    }
}
