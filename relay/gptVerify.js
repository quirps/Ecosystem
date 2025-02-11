const ethers = require("ethers");

const msgParams = {
    domain: {
        chainId: 1,
        name: 'Ether Mail',
        verifyingContract: "0x358AA13c52544ECCEF6B0ADD0f801012ADAD5eE3",
        version: '1',
    },
    types: {
        EIP712Domain: [
            { name: 'name', type: 'string' },
            { name: 'version', type: 'string' },
            { name: 'chainId', type: 'uint256' },
            { name: 'verifyingContract', type: 'address' },
        ],
        Member: [
            { name: 'owner', type: 'address' },
            { name: 'merkleRoot', type: 'bytes32' },
            { name: 'nonce', type: 'uint256' },
            { name: 'deadline', type: 'uint256' },
        ],
    },
    message: {
        owner: "0x1234567890abcdef1234567890abcdef12345678",
        merkleRoot: "0xabc123abc123abc123abc123abc123abc123abc123abc123abc123abc123abc1",
        nonce: 1,
        deadline: 1700000000,
    },
};

// Generate the EIP-712 hash
(async () => {
    try {
        const fullHash = ethers.utils._TypedDataEncoder.hash(
            msgParams.domain, // Domain details
            msgParams.types,  // Type definitions
            msgParams.message // Data to hash
        );
        console.log("EIP-712 Hash:", fullHash);
    } catch (error) {
        console.error("Error generating hash:", error.message);
    }
})();
