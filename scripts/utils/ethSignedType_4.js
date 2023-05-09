const { ethers } = require('ethers');


const types = {
   
    Mail: [
        { name: 'from', type: 'address' },
        { name: 'to', type: 'address' },
        { name: 'value', type: 'uint256' },
        { name: 'nonce', type: 'uint256' }
    ]
};
// Define the domain separator
const domainSeparator = {
    name: 'My DApp',
    version: '1.0.0',
    chainId: 1,
    verifyingContract: '0x9D7f74d0C41E726EC95884E0e97Fa6129e3b5E99',
};

// Define the message object
const message = {
    from: '0x1234567890123456789012345678901234567890',
    to: '0x0987654321098765432109876543210987654321',
    value: 303030, // 1 ETH
    nonce: 123,
};
let res = types.Mail.map  ((e)=>e.type)
console.log(Object.values(message))
console.log(res)
let abiCoder = new ethers.utils.AbiCoder()
let data = abiCoder.encode(res,Object.values(message))

let hash = ethers.utils.keccak256(data)
console.log(`hashedMessage - ${hash}`)
console.log(`serialized message - ${data}`)
// Sign the message using eth_SignTypedData_v4
const privateKey = '0x0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
const signer = new ethers.Wallet(privateKey);
//signer.address is used as the input parametery on the verify method. 
console.log(` Signer Address - ${signer.address}` )
async function main() {
    const signature = await signer._signTypedData(domainSeparator,types, message);
    console.log(`Signature - ${signature}` );

}


main()
