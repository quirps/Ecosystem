
/* global ethers task */

const { getWallets } = require('./scripts/hardhatAccountGenerator.js')
const NUM_USERS  = 40;
//require("hardhat-gas-reporter");
require("@nomicfoundation/hardhat-toolbox");
require("hardhat-diamond-abi");
// require("./diamondABItest");


const { facets : FACETS} = require('./deploy/ecosystem/versions/0.0.0.ts')


WALLET_BASE_AMOUNT = "10000000000000000000000000000" // 10**30

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  typechain: {
    outDir: "typechain-types",
    target: "ethers-v5",
  },
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
  defaultNetwork: "sepolia",
  networks: {
      hardhat: {
     accounts: getWallets('hardhat'),
      //  blockGasLimit: 10000000,
        gas: 900719925474099,  // 12 million
        blockGasLimit : 900719925474099,
      },
      sepolia: {
        url: "https://rpc-sepolia.rockx.com",
        accounts : ["401e06b76938af3a12335038ebc70fd6547a885fe19bceb4ae60d96bd69e9595"]
      },
    localhost: {
      accounts: getWallets('localhost'),
      // blockGasLimit: 10000000,
      url: "http://127.0.0.1:8545",
      gas: 900719925474099,  // 12 million
      blockGasLimit : 900719925474099
    }
  }
}

task("fundwallet", "Send ETH to own test account")
  .addParam("to", "Address you want to fund")
  .addOptionalParam("amount", "Amount to send in ether, default 10")
  .setAction(async (taskArgs, { network, ethers }) => {

    let to = await ethers.utils.getAddress(taskArgs.to);
    const amount = taskArgs.amount ? taskArgs.amount : "10";
    const accounts = await ethers.provider.listAccounts();
    const fromSigner = await ethers.provider.getSigner(accounts[0]);
    const fromAddress = await fromSigner.getAddress();
    console.log(`Signer Address - ${fromAddress}`)
    const txRequest = {
      from: fromAddress,
      to,
      value: ethers.utils.parseUnits(
        amount,
        "ether"
      ).toHexString(),
    };
    const txResponse = await fromSigner.sendTransaction(txRequest);
    await txResponse.wait();
    console.log(`wallet ${to} funded with ${amount} ETH at transaction ${txResponse.hash}`);
  });
//Output AST

// const execSync = require('child_process').execSync;

// task("compile:ast", "Compiles the contracts and outputs the AST")
//   .setAction(async () => {
//     const contractsDir = path.resolve(__dirname, "./contracts");

//     // Compile using solc and capture the output
//     const output = execSync(`solc --combined-json ast ${contractsDir}/*.sol`, { encoding: "utf8" });
//     const parsedOutput = JSON.parse(output);

//     // Write ASTs to separate files
//     for (const contractPath in parsedOutput.sources) {
//       const contractName = path.basename(contractPath, '.sol');
//       fs.writeFileSync(
//         path.resolve(__dirname, `./artifacts/${contractName}.ast.json`),
//         JSON.stringify(parsedOutput.sources[contractPath].AST, null, 2)
//       );
//     }
//   });