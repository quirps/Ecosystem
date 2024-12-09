
/* global ethers task */
const fs = require('fs');
const path = require('path');
const { generateWallets } = require('./scripts/hardhatAccountGenerator.js')
const NUM_USERS  = 20;
//require("hardhat-gas-reporter");
require("@nomicfoundation/hardhat-toolbox");
require("hardhat-diamond-abi");
require("./diamondABItest");


const { facets : FACETS} = require('./deploy/ecosystem/versions/0.0.0.ts')
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


WALLET_BASE_AMOUNT = "10000000000000000000000000000" // 10**30

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
     }
      // 'contracts/facets/DiamondLoupeFacet.sol:DiamondLoupeFacet'
      // console.log(abiElement.name)
      return FACETS.includes(currentContract) && fullyQualifiedName.includes('contracts/facets');
    },
    strict: false
  },
  settings: {
    outputSelection: {
      "*": {
        "*": ["*"],      // This line compiles everything for your contracts
        "": ["ast"]     // This line outputs the AST for your contracts
      }
    },
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
      accounts: generateWallets(NUM_USERS, WALLET_BASE_AMOUNT),
      //blockGasLimit: 10000000
      gas: 900719925474099,  // 12 million
      blockGasLimit : 900719925474099
    }
  }
}


//Output AST

const execSync = require('child_process').execSync;

task("compile:ast", "Compiles the contracts and outputs the AST")
  .setAction(async () => {
    const contractsDir = path.resolve(__dirname, "./contracts");

    // Compile using solc and capture the output
    const output = execSync(`solc --combined-json ast ${contractsDir}/*.sol`, { encoding: "utf8" });
    const parsedOutput = JSON.parse(output);

    // Write ASTs to separate files
    for (const contractPath in parsedOutput.sources) {
      const contractName = path.basename(contractPath, '.sol');
      fs.writeFileSync(
        path.resolve(__dirname, `./artifacts/${contractName}.ast.json`),
        JSON.stringify(parsedOutput.sources[contractPath].AST, null, 2)
      );
    }
  });