const { signTypedData } = require('@metamask/eth-sig-util')
const {faker} = require('@faker-js/faker')
const {ethers} = require('ethers')
/**
 * Remix Input format for type {address{uint48,uint32}}
 * [
    ["0x1234567890123456789012345678901234567890", [1625136000, 10]],
    ["0xabcdefabcdefabcdefabcdefabcdefabcdefabcd", [1625136100, 8]],
    ["0x9876543210987654321098765432109876543210", [1625136200, 12]]
]
 */
function generateMemberSignature(verifyingContract, chainId, signer, privateKey, nonce, amount ){
    let msgParams = {

        domain: {
            // This defines the network, in this case, Mainnet.
            chainId: chainId,
            // Give a user-friendly name to the specific contract you're signing for.
            name: 'Ether Mail',
            // Add a verifying contract to make sure you're establishing contracts with the proper entity.
            verifyingContract: verifyingContract,
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
                { name: 'data', type: 'bytes32' }
            ],
           
        },
        message: {
            owner: signer.address,
            nonce : nonce,
            data : []
        }
    };
    let _data = generateData(amount)
    let DataType = "tuple(address memberAddress, tuple(uint48 timestamp, uint32 rank) memberRank)[]"
    console.log(3)
    const messageHash = ethers.utils.keccak256(ethers.utils.defaultAbiCoder.encode([DataType], [_data]));
    console.log(4)
    let privKeyBytes = ethers.utils.arrayify(privateKey)
    msgParams.message.data = messageHash;
    console.log(msgParams)
    
    //sign message
    const signature = signTypedData({ privateKey: privKeyBytes, data: msgParams, version: 'V4' });
    console.log(signature)
    let sigComponents = ethers.utils.splitSignature(signature)
    sigComponents.data = _data;
    return sigComponents
}

exports.generateMemberSignature = generateMemberSignature

function generateData(amount){
    let _data = []
    for(let i = 0; i < amount; i++){
        _data.push ( 
            {
                memberAddress: faker.finance.ethereumAddress(),
                memberRank : {
                    timestamp : getRandomInt(10000000) ,
                    rank :  getRandomInt(10000) 
                }
            }
        )
    }
   
    console.log( _data )
    return _data
}
function getRandomInt(max) {
  return Math.floor(Math.random() * max);
}




