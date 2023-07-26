const ethers = require("ethers")
const { signTypedData } = require('@metamask/eth-sig-util')
const {faker} = require('@faker-js/faker')
/*WORKING VERIFCATION, 17 REMIX*/

// All properties on a domain are optional
let msgParams = {

    domain: {
        // This defines the network, in this case, Mainnet.
        chainId: 1,
        // Give a user-friendly name to the specific contract you're signing for.
        name: 'Ether Mail',
        // Add a verifying contract to make sure you're establishing contracts with the proper entity.
        verifyingContract:"0xd2a5bC10698FD955D1Fe6cb468a17809A08fd005",
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
            { name: 'nonce', type: 'uint256' },
            { name: 'data', type: 'App[]' }
        ],
        App:[
            { name: 'user', type: 'address' },
            { name: 'a', type: 'uint256' },
            { name: 'b', type: 'uint128' }
        ]

    },
};

class Message {
    constructor(owner, nonce,data) {
        this.owner = owner;
        this.nonce = nonce;
        this.data = data;
    }
    resource() {
        return {
            message: {
                owner:this.owner,
                nonce : this.nonce,
                data: this.data
            }
        }
    }
}
async function main(owner, nonce) {
    //add user parameters
    data = generateData(3)
    let message = new Message(owner, nonce, data);
    msgParams['message'] = message;

    //create key and format
    let signer = await ethers.Wallet.createRandom()
    msgParams.message.owner = signer.address;
    console.log(signer.address + " signerAddress")
    let privKeyBytes = ethers.utils.arrayify(signer.privateKey)
    console.log(msgParams)
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
main("", 394 )
//stringToBytes32("pooperscooper")
console.log( ethers.utils.formatBytes32String( "pooperscooper" ) + " merkleRoot")


function generateData(amount){
    let _data = []
    for(let i = 0; i < amount; i++){
        _data.push ( 
            {
                'user': faker.finance.ethereumAddress(),
                'a' : getRandomInt(10000),
                'b' : getRandomInt(10000)
            }
        )
    }
    console.log( _data )
    return _data
}
function getRandomInt(max) {
  return Math.floor(Math.random() * max);
}
module.exports = {main}


