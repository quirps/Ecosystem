const { ethers } = require("hardhat");

async function getBytecode(address) {
  // Connect to the Ethereum network
  const provider = ethers.getDefaultProvider("sepolia"); // or "ropsten", "rinkeby", etc.

  // Get the bytecode at the specified address
  const bytecode = await provider.getCode(address);

  if (bytecode === "0x") {
    console.log("No bytecode found at the given address. It might be an EOA (Externally Owned Account).");
  } else {
    console.log("Bytecode at address", address, ":", bytecode);
  }
}

// Replace with the Ethereum address you want to query
const address = "0x4827d2988aD7a47b76217eb66b3f841d3AcA907c";

getBytecode(address).catch((error) => {
  console.error(error);
  process.exitCode = 1;
});