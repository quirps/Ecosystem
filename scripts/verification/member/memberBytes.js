const { ethers } = require("hardhat");
const { signTypedData } = require('@metamask/eth-sig-util')

// Define domain, types, and message for EIP-712
const domain = {
    name: "Ether Mail",
    version: "1",
    chainId: 1,
    verifyingContract: "0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC",
};

const types = {
    // Primary type definition
    Member: [
        { name: "owner", type: "address" },
        { name: "merkleRoot", type: "bytes32" },
        { name: "nonce", type: "uint256" },
        { name: "deadline", type: "uint256" },
    ],
};

const message = {
    owner: "0x1234567890abcdef1234567890abcdef12345678",
    merkleRoot: "0xabc123abc123abc123abc123abc123abc123abc123abc123abc123abc123abc1",
    nonce: 1,
    deadline: 1700000000,
};
const primaryType  = 'Member'
const data = {

    domain, types,message, primaryType,
};
// Generate the EIP-712 hash
(async () => {
    try {
        const fullHash = ethers.utils._TypedDataEncoder.hash(domain, types, message);
        console.log("EIP-712 Hash:", fullHash);

        let signer = await ethers.Wallet.createRandom()
        let privKeyBytes = ethers.utils.arrayify(signer.privateKey)
        const signature = signTypedData({ privateKey: privKeyBytes, data, version: 'V4' });
        const {v,r,s} = ethers.utils.splitSignature(signature)

        console.log(signature)
        console.log(v,r,s)
        const SigVerify = await ethers.getContractFactory("SigVerify")
        const sigVerify = await SigVerify.deploy();
 
        const result = await sigVerify.verify(fullHash, v, r, s) 
        console.log(result)

    } catch (error) {
        console.error("Error generating hash:", error.message);
    }
})();
