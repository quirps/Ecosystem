
/* global ethers task */

const { getWallets } = require('./scripts/hardhatAccountGenerator.js')
const dotenv = require('dotenv')
const NUM_USERS  = 40;
//require("hardhat-gas-reporter");
require("@nomicfoundation/hardhat-toolbox");
require("hardhat-diamond-abi");
require("hardhat-deploy");
// require("./diamondABItest");
dotenv.config()
const FACETS = [
    'DiamondCutFacet', 'DiamondInit', 'DiamondLoupeFacet', 'ERC1155Ecosystem', 'ERC1155Transfer','ERC1155ReceiverEcosystem','ERC20Ecosystem', 'MemberRegistry',
    'MembershipLevels', 'Moderator', 'OwnershipFacet', 'EventFactory', 'StakeConfig','ERC2981','TicketCreate','UtilityAddressManagement',
]
const INTERFACES = [
  'IEventFacet'
]
WALLET_BASE_AMOUNT = "10000000000000000000000000000" // 10**30

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  
  etherscan:process.env.ETHERSCAN_API_KEY,
  sources: ["./contracts", "./node_modules/registry/contracts"],
  solidity: '0.8.28',
  diamondAbi: {
    // (required) The name of your Diamond ABI
    name: "Ecosystem",
    filter: function (abiElement, index, fullAbi, fullyQualifiedName) {
      let startIndex = fullyQualifiedName.indexOf(':') 
      let currentContract = fullyQualifiedName.substr(startIndex + 1)
    
      return (
        (FACETS.includes(currentContract) && fullyQualifiedName.includes('contracts/facets')) ||
        (INTERFACES.includes(currentContract) && fullyQualifiedName.includes('contracts/facets'))
      );
    },
    strict: false
  },
  paths: {
    // ... sources, tests, cache, artifacts ...
    deploy: "deploy",
    deployments: "deployments",
    imports: "imports" // Needed by hardhat-deploy external feature
  },
  solidity : {
    version : "0.8.28",
    settings: {
      viaIR: true,
      evmVersion: "cancun",  // Explicitly set to Cancun
      outputSelection: {
        "*": {
          "*": ["*"],      // This line compiles everything for your contracts
          "": ["ast"]     // This line outputs the AST for your contracts
        }
      },
      optimizer: {
        enabled: true,
        runs: 200
      }
    },
     overrides: {
       "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2Mock.sol": {
         version: "0.8.7", // Specify compiler if needed
         settings: { /* ... */ }
       }
     }
  },
  gasReporter: {
    enabled: true,
    currency: 'CHF',
    gasPrice: 21
  },
  defaultNetwork: "hardhat",
  networks: {
      hardhat: {
     accounts: getWallets('hardhat'),
      //  blockGasLimit: 10000000,
        gas: 900719925474099,  // 12 million
        blockGasLimit : 900719925474099,
      },
      sepolia: {
        accounts: getWallets('localhost'),
        url: "https://0xrpc.io/sep",
        //accounts : ["401e06b76938af3a12335038ebc70fd6547a885fe19bceb4ae60d96bd69e9595"]
      },
    localhost: {
      accounts: getWallets('localhost'),
      // blockGasLimit: 10000000,
      url: "http://127.0.0.1:8545",
      gas: 900719925474099,  // 12 million
      blockGasLimit : 900719925474099
    }
  },
  namedAccounts: {
    deployer: {
      default: 0, // Default to the first account from the node
      // Example: Specify different deployers per network
      // 1: "0xYourMainnetDeployerAddress", // Mainnet (chainId 1)
      // 11155111: "0xYourSepoliaDeployerAddress", // Sepolia
    },
    user1 : {
      default : 1
    },
    user2 : {
      default : 2
    },
    user3 : {
      default : 3
    },
    owner : {
      default : 4,
    },
    ecosystem1Owner :{
      default : 5,
    }, ecosystem2Owner : {
      default : 6,
    }, royaltyReceiver : {
      default : 7,
    },
    paths: {
      sources: "./contracts",
      tests: "./test",
      cache: "./cache",
      artifacts: "./artifacts",
      deploy: "./deploy", // Specify deploy folder
      deployments: "./deployments", // Specify deployments folder
    },
  
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