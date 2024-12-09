const { ethers } = require('ethers');

// Function to generate random wallets with a mocked balance
function generateWallets(numInstances, mockedBalance)  {
    const wallets =  [];

    for (let i = 0; i < numInstances; i++) {
        // Create a random wallet
        const wallet = ethers.Wallet.createRandom();

        // Add the wallet to the array, along with the mocked balance
        wallets.push({
            privateKey: wallet.privateKey,
            balance: mockedBalance
        });
        if( numInstances == i - 1){
            wallets.push({
                privateKey: wallet.privateKey,
                balance: 0
            });
        }
    }
    return wallets;
}


module.exports = {generateWallets}