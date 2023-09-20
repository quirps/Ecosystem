
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
          privateKey: '0xbb15a01531bf42283df04666acf30e465ace0a8eb399156c3daefdb0bf535641',
          balance: '45728182267703928635086400'
        },
        {
          privateKey: '0xb25358113c060595c5a94e1b8a7534f303cb365e4d26786e2b6635fce84b2329',
          balance: '45728182267703928635086400'
        },
        {
          privateKey: '0xe7fc53d5c5f9f2e0c46689eb80ef4606f04c78d693d2de747244e024e6c1918d',
          balance: '45728182267703928635086400'
        },
        {
          privateKey: '0x80f79907a62e092f769de1bd680ef13f56ea0e3183540d13ff6bd7f4f3f6c3f7',
          balance: '45728182267703928635086400'
        },
        {
          privateKey: '0xed00e6c3c42bb3b71031cf8bb11ee750523ab73ff9c8cb9b99450382e9fc25ec',
          balance: '45728182267703928635086400'
        },
        {
          privateKey: '0x28d5cacc711de1eb61dd45510bc5b3305bf261e77050ac18fc1b3e51157eb248',
          balance: '45728182267703928635086400'
        },
        {
          privateKey: '0x00839dcc5f0a0b3231024340e72d2b1ebaffa85396f816dd1554c9a5c2a71077',
          balance: '45728182267703928635086400'
        },
        {
          privateKey: '0x5c94571b808d49e885bb9600ef5e7ec72e7ff49812006f5cf0dee68bcd8ed88a',
          balance: '45728182267703928635086400'
        },
        {
          privateKey: '0xcb168e8c2ff46486bd3b3509449700c8c6feeaa253eef0b1b861ed1bfc3e7c7b',
          balance: '45728182267703928635086400'
        },
        {
          privateKey: '0x99c3dac51e716b62d66e7b4c620315d62d1693db2db932c34df1ee7b8ee8efd7',
          balance: '45728182267703928635086400'
        }
      ],
      //blockGasLimit: 10000000
      gas: 333333329900000,  // 12 million
      blockGasLimit : 3333333299000003
    }
  }
}
