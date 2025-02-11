const  { ethers } = require("hardhat");
const hre = require('hardhat')
const { signTypedData, recoverTypedSignature, TypedDataUtils } = require('@metamask/eth-sig-util')
const sigUtil = require('eth-sig-util')

const {
    TrustedForwarder,
  }  = require("../../deploy/attach/attatchments")



const types = {
    // Primary type definition
    Message: [
        { name: "signer", type: "address" },
        { name: "target", type: "address" },
        { name: "paymasterData", type: "bytes" },
        { name: "targetData", type: "bytes" },
        { name: "gasLimit", type: "uint256" },
        { name: "nonce", type: "uint256" },
        { name: "deadline", type: "uint32" },
    ],
    EIP712Domain : [
        { name: 'name', type: 'string' },
        { name: 'version', type: 'string' },
        { name: 'chainId', type: 'uint256' },
        { name: 'verifyingContract', type: 'address' },
      ]
};
const primaryType  = 'Message'

class TxFactory{
    domain;
    data;
    constructor(verifyingContract){
        this.verifyingContract = verifyingContract
    }
    //only needs to be done during testing, will be constant in production
    async initializeDomain(){
        const chainId = await hre.network.provider.send("eth_chainId");
        this.domain = {
            name : "MassDX", 
            version : "1.0.0",
            verifyingContract :this.verifyingContract,
            chainId
        }
        this.data = {domain : this.domain, types, primaryType}
    }
    
    signMessage(privKeyBytes, message){
        this.data.message = message;
        //wont take BigInt, so gas limit field
        //turns out they take hex strings, number, and BN like object
        const signature = signTypedData( {privateKey :  privKeyBytes,  data : this.data, version:'V4' }  );
        console.log(signature)
        //const hash = TypedDataUtils.eip712Hash(this.data, 'V4')

        return { signature }
    }
    getSigner(){
        //replace with client getter
    }
}

module.exports = {TxFactory}

/**
 * How do we restrict gassless txs ecosystem owner restricted domain?
 * Clearly ecosystem functionality is desired, along with apps used
 * by the ecosystem. 
 */