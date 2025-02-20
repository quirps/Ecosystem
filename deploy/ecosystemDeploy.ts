const { ethers } = require('hardhat') 
import { ecosystemDeploy } from "./ecosystem/ecosystemDeploy"
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



async function deployVersion(){
    const version = "0.0.0"
    const registryAddress = "0x4827d2988aD7a47b76217eb66b3f841d3AcA907c"
    const registry = await ethers.getContractAt( "EcosystemRegistry", registryAddress)
    const versionBytes = ethers.utils.formatBytes32String(version);

    const result = await registry.callStatic.getVersion( versionBytes )
    console.log(3)

    const name = "TestEcosystem"
    const salt : number= 34242424244;
    let diamondBytecode = (await ethers.getContractFactory('Diamond')).bytecode;

    const tx = await registry.deployVersion(versionBytes, name, salt, diamondBytecode);


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
eventTest()
//ticketCreate(uint192 _amount, TicketMeta memory _ticketMeta, LibERC1155TransferConstraints.Constraints memory _constraints)
//Registry Address  "0x4827d2988aD7a47b76217eb66b3f841d3AcA907c"
//Ecosystem Address "0x6b5b237601c2EcB12d8b8504435A464b38BAf7Fd"