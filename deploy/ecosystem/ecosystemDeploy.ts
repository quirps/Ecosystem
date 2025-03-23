const { facetDeploy, registryDeploy, deployEcosystems, registryUploadVersion} = require('./preDiamondDeploy')
const { ethers } = require('hardhat') 

import type { BigNumberish, Signer } from "ethers";

import type { EthereumAddress, Facet } from "../../types/web3";
import type { EcosystemConfig } from "../../types/deploy/userConfig" 

import type { Ecosystem } from "../../types/ethers-contracts/Ecosystem"

const MAX_TICKET_AMOUNT = BigInt(10000000000000000000000000000) ; // 10**30
const MAX_TICKET_ID = 100;

// Here we deploy the supporting infrastructure enabling ecosystem deployment
// and then deploy and populate all ecosystems in the ecosystemConfig parameter
export async function ecosystemDeploy( ecosystemConfigs : Partial<EcosystemConfig>[])  {
    //deploy registry and diamondDeploy
    const {registry, diamondAddress} = await registryDeploy();
    const facets : { [ version : string ] : Facet[] }= {};
    const ecosystems : { [ name : string] : Ecosystem} = {}

    for( let _ecosystemConfig of ecosystemConfigs){
        let ecosystem;
        let _version = _ecosystemConfig.version!!
        //set the configured owner for this ecosystem 
        
        //only need to deploy facets once per version. 
        //can still be optimized as this doesn't check for common facets between
        //versions
        if ( facets[ _version ] === undefined ){
            //cache facets
            let _facets = await facetDeploy( _version);
            facets[ _version ] = _facets;
            
            //upload version
            await registryUploadVersion( _facets , registry, _version );
        }      
        console.log(` Registry Address Sepolia - ${registry.address}`)
        
        ecosystem = await deployEcosystems( _ecosystemConfig, registry, _ecosystemConfig.owner )
        console.log(`Ecosystem Address Sepolia ${ecosystem.address}`)
        ecosystem.owner = _ecosystemConfig.owner;
        console.log(_ecosystemConfig)
        ecosystems[ _ecosystemConfig.name!!] = ecosystem; 
        // populate ecosystem's tokens/tickets 
        // await mintUniformBatch( ecosystem, ecosystem.own er, MAX_TICKET_ID, MAX_TICKET_AMOUNT)
 
        // ecosystems[ _ecosystemConfig.name!! ] = ecosystem;
    }



    console.log("finished")
    return { ecosystems, registry }
}

// populate token/tickets , ids 0-100 uniformly set to POPULATION_AMOUNT
async function mintUniformBatch( _ecosystem : Ecosystem, owner : Signer , MAX_TICKET_ID : number, MAX_TICKET_AMOUNT : BigNumberish) {
    let ecosystemOwner;
    // Create arrays for ids and amounts
    const ids = [];
    const amounts : BigNumberish[] = []; 
    const ownerAddress = await owner.getAddress();
    // Loop through and populate ids and amounts arrays
    for (let i = 0; i <= MAX_TICKET_ID; i++) {
        ids.push(i);             // Token ID (from 0 to maxId)
        amounts.push(MAX_TICKET_AMOUNT); // Uniform amount for each token ID
    }
 
    ecosystemOwner = _ecosystem.connect( owner );
    // Call the mintBatch function
    const tx = await ecosystemOwner.mintBatch( ownerAddress , ids, amounts, "0x"); // '0x' is for empty data
    await tx.wait(); // Wait for the transaction to be mined

    console.log('Minting transaction successful!');
}