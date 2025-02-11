const fs = require('fs')
const { ethers } = require('ethers');

// Function to generate random wallets with a mocked balance
function generateWallets(numInstances, mockedBalance, hardhat = false)  {
    const wallets =  [];

    for (let i = 0; i < numInstances; i++) {
        // Create a random wallet
        const wallet = ethers.Wallet.createRandom();

        // Add the wallet to the array, along with the mocked balance
        let element = hardhat ? {
                                    privateKey: wallet.privateKey,
                                    balance: mockedBalance
                                } 
                              : wallet.privateKey;
        wallets.push( element );
        if( numInstances == i - 1){
            let finalElement = hardhat ? {
                                            privateKey: wallet.privateKey,
                                            balance: 0
                                        }
                                        : wallet.privateKey
            wallets.push( finalElement );
        }
    }
    return wallets;
}
function generateWalletsStatic(numInstances, mockedBalance, hardhat = false)  {
    const walletsHardhat =  [];
    const walletsLocalHost = [];
    for (let i = 0; i < numInstances; i++) {
        // Create a random wallet
        const wallet = ethers.Wallet.createRandom();

        // Add the wallet to the array, along with the mocked balance
        walletsHardhat .push(  {           privateKey: wallet.privateKey,
                                    balance: mockedBalance
                                } 
                            ) 
        walletsLocalHost.push( wallet.privateKey )
        if( numInstances == i - 1){
            walletsHardhat.push( {
                privateKey: wallet.privateKey,
                balance: 0
            } )
            walletsLocalHost.push( wallet.privateKey )
        }
    }
    const wallets = JSON.stringify(
        {
            hardhat : walletsHardhat,
            localhost : walletsLocalHost
        }
    )
    fs.writeFileSync("./scripts/wallets.json", wallets)
    console.log(`Hardhat wallets - ${walletsHardhat}`)
    console.log(`Localhost wallets - ${walletsLocalHost}`)
}

function getWallets( walletType ){
    const _wallets = JSON.parse( fs.readFileSync("./scripts/wallets.json",'utf8') )
    if( walletType == 'hardhat'){
        return _wallets['hardhat']
    }
    else if( walletType == 'localhost'){
        return _wallets['localhost']
    }
}
module.exports = {generateWallets, getWallets, generateWalletsStatic}
// WALLET_BASE_AMOUNT = "10000000000000000000000000000" 
// generateWalletsStatic(40, WALLET_BASE_AMOUNT)

