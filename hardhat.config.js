
/* global ethers task */
//require("hardhat-gas-reporter");
require("@nomicfoundation/hardhat-toolbox");
require("hardhat-diamond-abi");
const {FACETS} = require('./deploy/constants')
//require("hardhat-tracer");
// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
//priv key - '0x032939ca9fc384fb639665e220f931cfdc9a114a0d7a5d3b4786eeac4a7bf3c1'
//address - '0xa635280ede965d267C818223Ab219528c7557B64'
task('accounts', 'Prints the list of accounts', async () => {
  const accounts = await ethers.getSigners()

  for (const account of accounts) {
    console.log(account.address)
  }
})

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  sources: ["./contracts", "./node_modules/registry/contracts"],
  solidity: '0.8.9',
  diamondAbi: {
    // (required) The name of your Diamond ABI
    name: "Ecosystem",
    filter: function (abiElement, index, fullAbi, fullyQualifiedName) {
     let startIndex = fullyQualifiedName.indexOf(':') 
     let currentContract = fullyQualifiedName.substr(startIndex + 1)
     if ( FACETS.includes(currentContract) && fullyQualifiedName.includes('contracts/facets') ){
      console.log(3)
     }
      // 'contracts/facets/DiamondLoupeFacet.sol:DiamondLoupeFacet'
      // console.log(abiElement.name)
      return FACETS.includes(currentContract) && fullyQualifiedName.includes('contracts/facets');
    },
    strict: false
  },
  settings: {
    optimizer: {
      enabled: true,
      runs: 80
    }
  },
  gasReporter: {
    enabled: true,
    currency: 'CHF',
    gasPrice: 21
  },
  networks: {
    hardhat: {
      accounts: [
        {
          privateKey: "0xe34ee8c4ca712c3c6b9d62682e0134352f309ece9cd3c5c1dadaf8b1e4e4608f",
          balance: "45728182267703928635086400"  // 10,000 ETH in wei
        }
        
      ],
      //blockGasLimit: 10000000
      gas: 333333329900000,  // 12 million
      blockGasLimit : 3333333299000003
    }
  }
}
