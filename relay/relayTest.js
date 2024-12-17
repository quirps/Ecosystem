// scripts/testRelay.js
const { ethers } = require("hardhat");
const DUMMY_INPUT = BigInt("11234302502850238502580808")
const UNKNOWN_LEFTOVER_GAS = 133;
export async function relayDeploy() {
  
  // Deploy SimpleTarget
  const SimpleTarget = await ethers.getContractFactory("Target");
  const simpleTarget = await SimpleTarget.deploy();
  await simpleTarget.deployed();

  console.log("SimpleTarget deployed to:", simpleTarget.address);

  // Deploy TrustedForwarder
  const TrustedForwarder = await ethers.getContractFactory("TrustedForwarder");
  const trustedForwarder = await TrustedForwarder.deploy(ethers.constants.AddressZero, ethers.constants.AddressZero, "Test", "Test");
  await trustedForwarder.deployed();

  

  console.log("TrustedForwarder deployed to:", trustedForwarder.address);

   // Deploy Paymaster
   const Paymaster = await ethers.getContractFactory("Paymaster");
   const paymaster = await Paymaster.deploy();
   await paymaster.deployed();

  console.log("TrustedForwarder deployed to:", trustedForwarder.address);

  // Deploy Relay
  const Relay = await ethers.getContractFactory("Relay");
  const relay = await Relay.deploy(trustedForwarder.address);
  await relay.deployed();

  console.log("Relay deployed to:", relay.address);

  // Encode the function call to SimpleTarget
  const data = simpleTarget.interface.encodeFunctionData("storeData", [DUMMY_INPUT]);

  // Estimate gas off-chain
  const estimatedGas = await simpleTarget.estimateGas.storeData(DUMMY_INPUT);

  console.log("Estimated Gas (off-chain):", estimatedGas.toString());

  // Relay the meta-transaction and capture the gas usage on-chain
  const tx = await relay.relayMetaTransaction(simpleTarget.address, data);
  const receipt = await tx.wait();

  // Fetch gasUsed from the on-chain event
  const event = receipt.events.find((e) => e.event === "MetaTransactionRelayed");

  const initialGas = event.args.intialGas;
  console.log(`Initial Gas ${initialGas}`)
  const finalGas = event.args.finalGas;
  console.log(`Final Gas ${finalGas}`)
  const mainGas = initialGas - finalGas;

  console.log(`Main On-Chain Gas Used ${mainGas}`)
  const preGas = estimatePreGas( data )
  const postGas = estimatePostGas()

  const gasUsedOnChain = BigInt(preGas) + BigInt(mainGas) + BigInt( postGas) + BigInt(UNKNOWN_LEFTOVER_GAS);

  console.log("Gas Used (on-chain):", gasUsedOnChain.toString());

  //Actual gas used 
  console.log(`Actual gas used - ${receipt.cumulativeGasUsed.toString()}`)

  //Disagreement of on-chain gas calculation vs real value
  console.log(`Real gas cosnumed vs On-chain estimate ${BigInt(receipt.cumulativeGasUsed) - gasUsedOnChain}`)

  return {target : simpleTarget, relay, trustedForwarder, paymaster}
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});


function estimatePreGas(calldata) {
  if (calldata.startsWith('0x')) {
    calldata = hexStringToByteArray(calldata)
  }

  // Intrinsic gas (21,000) for transaction execution
  const intrinsicGas = 21000;

  // Calldata gas cost (4 gas per zero byte, 16 gas per non-zero byte)
  const calldataGas = calldata
    .reduce((acc, byte) => acc + (byte === 0 ? 4 : 16), 0);
  console.log(`Calldata gas amount ${calldataGas}`)
  // Contract call overhead (700 gas)
  const contractCallOverhead = 700;

  // Memory expansion cost (initial fixed cost, optional)
  const memoryExpansion = 1000; // Example value, adjust if needed


  // Total pre-gas estimate
  return intrinsicGas + calldataGas + contractCallOverhead + memoryExpansion;
}

function estimatePostGas(eventDataLength = 32) {
  // Fixed cost to emit event (375 gas) + 8 gas per byte of event data
  const eventGas = 375 + 8 * eventDataLength;

  console.log(`Event gas amount ${eventGas}`)

  // Return data encoding cost (500 gas)
  const returnDataGas = 500;

  // Additional overhead for storage updates or other finalization (optional buffer)
  const storageUpdateOverhead = 1000; // Example value

  // Total post-gas estimate
  return eventGas + returnDataGas + storageUpdateOverhead;
}

function hexStringToByteArray(hexString) {
  // Remove the '0x' prefix if it exists
  if (hexString.startsWith('0x')) {
    hexString = hexString.slice(2);
  }

  // Convert the hex string into a byte array
  const byteArray = [];
  for (let i = 0; i < hexString.length; i += 2) {
    const byte = parseInt(hexString.substr(i, 2), 16);
    byteArray.push(byte);
  }

  return byteArray;
}


//Gas estimate discrepancy
//for uint256 and arbitray inputs - 133