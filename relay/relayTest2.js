const ethers = require('ethers');

async function signMetaTransaction(wallet, contractAddress, nonce, data) {
    const domain = {
        name: 'MetaTransactionVerifier',
        version: '1',
        chainId: 1, // Change to your network chain ID
        verifyingContract: contractAddress
    };

    const types = {
        MetaTransaction: [
           { name: "signer", type: "address" },
        { name: "target", type: "address" },
        { name: "paymasterData", type: "bytes" },
        { name: "targetData", type: "bytes" },
        { name: "gasLimit", type: "uint256" },
        { name: "nonce", type: "uint256" },
        { name: "deadline", type: "uint32" },
        ]
    };

    const metaTx = {
        from: wallet.address,
        nonce: nonce,
        data: data
    };

    // Sign using EIP-712
    const signature = await wallet._signTypedData(domain, types, metaTx);
    
    return {
        metaTx,
        signature
    };
}

async function main() {
    // Replace with your private key (be careful with private keys!)
    const privateKey = '0xYOUR_PRIVATE_KEY';
    const wallet = new ethers.Wallet(privateKey);
    
    // Contract address where the verification will happen
    const contractAddress = '0xYOUR_CONTRACT_ADDRESS';
    
    // Nonce (should be fetched from the contract)
    const nonce = 0;
    
    // Example data to include in the meta transaction
    const data = ethers.utils.defaultAbiCoder.encode(
        ["address", "address", "bytes", "bytes", "uint256", "uint256", "uint32"],
        ["0x1234567890abcdef1234567890abcdef12345678",
            "0x1234567890abcdef1234567890abcdef12345678",
            "0xabc123abc123abc123abc123abc123abc123abc123abc123abc123abc123abc1",
            "0x023442949495",
            "0x1000000000000000000",1,1900000000 ]
    );
    
    // Sign the meta transaction
    const signedData = await signMetaTransaction(wallet, contractAddress, nonce, data);
    
    console.log('Meta Transaction:');
    console.log(signedData.metaTx);
    console.log('\nSignature:');
    console.log(signedData.signature);
    
    // These are the values you would send to the contract
    console.log('\nValues to send to contract:');
    console.log('MetaTx.from:', signedData.metaTx.from);
    console.log('MetaTx.nonce:', signedData.metaTx.nonce);
    console.log('MetaTx.data:', signedData.metaTx.data);
    console.log('Signature:', signedData.signature);
}

main().catch(console.error);