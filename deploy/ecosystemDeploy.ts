const { ethers } = require('hardhat') 
import { ecosystemDeploy } from "./ecosystem/ecosystemDeploy"
import { deployEcosystems } from "./ecosystem/preDiamondDeploy"
import type { EcosystemConfig } from "../types/deploy/userConfig" 
import type { Signer } from "ethers" 
async function main(){
    const signers : Signer[] = await ethers.getSigners()
    const ecosystemConfig  : Partial<EcosystemConfig>[] = 
    [ {
        name : "TestEcosystem",
        version : "0.0.0",
        owner : signers[0]
    } ]
    ecosystemDeploy(ecosystemConfig);  
}  

async function getVersion(){
    const vn = "0.0.0"
    const _version =  ethers.utils.formatBytes32String(vn);
    const registryAddress = "0x4827d2988aD7a47b76217eb66b3f841d3AcA907c"
    const registry = await ethers.getContractAt( "EcosystemRegistry", registryAddress)
    const version = await registry.callStatic.getVersion( _version );
    console.log(version)
}

async function deployVersion(){
    const version = "0.0.0"
    const registryAddress = "0x6fdd8556E3EE3ecD85Bd0fF19f3DBFeb9e720F62"
    const registry = await ethers.getContractAt( "EcosystemRegistry", registryAddress)
    const versionBytes = ethers.utils.formatBytes32String(version);

    const result = await registry.callStatic.getVersion( versionBytes )
    console.log(3)

    const name = "TestEcosystems"
    const salt : number= 32341111142444;
    
    let diamondBytecode = (await ethers.getContractFactory('Diamond')).bytecode;
    const diamondAddress  = await registry.callStatic.deployVersion(versionBytes, name!!, salt, diamondBytecode);
    console.log(diamondAddress)
    const tx = await registry.deployVersion(versionBytes, name, salt, diamondBytecode,{gasLimit: 1000000}); 
    console.log(tx)
}
export async function _deployEcosystems(
   
) {
    const ecosystemConfig = {version : "0.0.0",
                        name : "Test1"
    }
    const registryAddress = "0x6fdd8556E3EE3ecD85Bd0fF19f3DBFeb9e720F62"
    const registry = await ethers.getContractAt( "EcosystemRegistry", registryAddress)
    const owner = (await ethers.getSigners() )[0]
    await deployEcosystems( ecosystemConfig, registry, owner)

}


async function eventTest(){
    const ECOYSYSTEM_ADDRESS = "0x6b5b237601c2EcB12d8b8504435A464b38BAf7Fd"
    const ecosystem = await ethers.getContractAt("Ecosystem", ECOYSYSTEM_ADDRESS)
    const owner = "0x2D08BDf3c61834F76Decaf6E85ffAecFeF02E605"
    const amount = BigInt(10)**BigInt(18)
    const nullBytes = ethers.utils.formatBytes32String("")
    const tx = await ecosystem.mint(owner, 0, amount, nullBytes)
    const txRec = await tx.wait()
    console.log(3)
}
deployVersion()
//ticketCreate(uint192 _amount, TicketMeta memory _ticketMeta, LibERC1155TransferConstraints.Constraints memory _constraints)
//Registry Address  "0x4827d2988aD7a47b76217eb66b3f841d3AcA907c"
//Ecosystem Address "0x6b5b237601c2EcB12d8b8504435A464b38BAf7Fd"


// Latest 
// Registry Address Sepolia - 0x6fdd8556E3EE3ecD85Bd0fF19f3DBFeb9e720F62
// Ecosystem Address Sepolia 0x1f8E23611b4e5f292c330972856283243557f964