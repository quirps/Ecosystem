const { ethers } = require("hardhat");
const { signTypedData, recoverTypedSignature, TypedDataUtils } = require('@metamask/eth-sig-util')

/**
 * Working, self contained! 
 * Now generalizing the message to a different set of data structures
 * and creating the class factory
 */
async function main(){
  
    // eth_signTypedData_v4 parameters. All of these parameters affect the resulting signature.
    // Define domain, types, and message for EIP-712
const domain = {
    name: "Ether Mail",
    version: "1",
    chainId: 1,
    verifyingContract: "0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC",
};

const types = {
    // Primary type definition
    Main: [
        { name: "signer", type: "address" },
        { name: "target", type: "address" },
        { name: "paymasterData", type: "bytes" },
        { name: "targetData", type: "bytes" },
        { name: "gasLimit", type: "uint256" },
        { name: "nonce", type: "uint256" },
        { name: "deadline", type: "uint32" },
    ],
};

const message = {
    signer: "0x1234567890abcdef1234567890abcdef12345678",
    target: "0x1234567890abcdef1234567890abcdef12345678",
    paymasterData: "0xabc123abc123abc123abc123abc123abc123abc123abc123abc123abc123abc1",
    targetData : "0x023442949495",
    gasLimit : "0x1000000000000000000",
    nonce: 1,
    deadline: 1700000000,
};

const primaryType  = 'Main'
const data = {

    domain, types,message, primaryType,
};


    
    let signer = await ethers.Wallet.createRandom()
    let privKeyBytes = ethers.utils.arrayify(signer.privateKey)

    const signature = signTypedData({ privateKey: privKeyBytes, data, version: 'V4' });
    const {v,r,s} = ethers.utils.splitSignature(signature)

       
          const recovered = recoverTypedSignature({
            data,
            signature: signature,
            version : 'V4'
          })
  
          if (
            ethers.utils.getAddress(recovered) ===
            ethers.utils.getAddress(signer.address)
          ) {
            console.log("Matched!")
          }
  
          //lets verify it on-chain
          const SigVerify = await ethers.getContractFactory("SigVerify")
        const sigVerify = await SigVerify.deploy();
        
        const hash = TypedDataUtils.eip712Hash(data, 'V4')
        const result = await sigVerify.callStatic.verify(hash, v, r, s) 
        console.log(result)
        console.log(signer.address)
        console.log(  ethers.utils.getAddress(recovered) )
}

main()