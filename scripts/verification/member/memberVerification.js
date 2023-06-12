const ethers = require("ethers")
const { signTypedData } = require('@metamask/eth-sig-util')
/*WORKING VERIFCATION, 17 REMIX*/

// All properties on a domain are optional
let msgParams = {

    domain: {
        // This defines the network, in this case, Mainnet.
        chainId: 1,
        // Give a user-friendly name to the specific contract you're signing for.
        name: 'Ether Mail',
        // Add a verifying contract to make sure you're establishing contracts with the proper entity.
        verifyingContract:"0x358AA13c52544ECCEF6B0ADD0f801012ADAD5eE3",
        // This identifies the latest version.
        version: '1',
    },

    // This defines the message you're proposing the user to sign, is dapp-specific, and contains
    // anything you want. There are no required fields. Be as explicit as possible when building out
    // the message schema.
   
    // This refers to the keys of the following types object.
    primaryType: 'Member',
    types: {
        // This refers to the domain the contract is hosted on.
        EIP712Domain: [
            { name: 'name', type: 'string' },
            { name: 'version', type: 'string' },
            { name: 'chainId', type: 'uint256' },
            { name: 'verifyingContract', type: 'address' },
        ],
        // Not an EIP712Domain definition.
        Member: [
            { name: 'owner', type: 'address' },
            { name: 'merkleRoot', type: 'bytes32' },
            { name: 'nonce', type: 'uint256' },
            { name: 'deadline', type: 'uint256' }
        ]
    },
};

class Message {
    constructor(owner, merkleRoot, nonce, deadline) {
        this.owner = owner;
        this.merkleRoot = merkleRoot;
        this.nonce = nonce;
        this.deadline = deadline;
    }
    resource() {
        return {
            message: {
                owner:this.owner,
                merkleRoot: this.merkleRoot,
                nonce : this.nonce,
                deadline : this.deadline
            }
        }
    }
}
async function main(owner, merkleRoot, nonce, deadline) {
    //add user parameters
    let message = new Message(owner, merkleRoot, nonce, deadline);
    msgParams['message'] = message;

    //create key and format
    let signer = await ethers.Wallet.createRandom()
    msgParams.message.owner = signer.address;
    console.log(signer.address + " signerAddress")
    let privKeyBytes = ethers.utils.arrayify(signer.privateKey)

    //sign message
    const signature = signTypedData({ privateKey: privKeyBytes, data: msgParams, version: 'V4' });
    console.log(signature)
    let sigComponents = ethers.utils.splitSignature(signature)
    console.log(sigComponents)
    // '0x463b9c9971d1a144507d2e905f4e98becd159139421a4bb8d3c9c2ed04eb401057dd0698d504fd6ca48829a3c8a7a98c1c961eae617096cb54264bbdd082e13d1c'
}
function stringToBytes32(_string){
    let abiEncoder = ethers.utils.defaultAbiCoder
    //console.log(ethers.utils.arrayify(_string))
    //abiEncoder.encode(['bytes32'],[ Buffer.from( _string ) ] )
}
main("0x1cBcbf4e933d12941f5944E72bB805594e687044", 
ethers.utils.formatBytes32String( "pooperscooper" ), 394, 1686560855 + 10000)
//stringToBytes32("pooperscooper")
console.log( ethers.utils.formatBytes32String( "pooperscooper" ) + " merkleRoot")


module.exports = {main}