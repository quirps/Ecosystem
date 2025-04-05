// scripts/deployNewVersion.js

const hre = require("hardhat");
const ethers = hre.ethers; // Convenient access to ethers components

async function main() {
    // --- CONFIGURATION (Fill these placeholders) ---

    // 1. Address of the deployed EcosystemRegistry contract
    const ECOSYSTEM_REGISTRY_ADDRESS = "0x99Bc9FE6bbFaE287CF2b662f1eb3F4E11B350B99"; // <-- REPLACE THIS

    // 2. Version Number (bytes32 format - must be a 32-byte hex string)
    // Example: ethers.utils.formatBytes32String("1.0.0") or a specific keccak256 hash
    const VERSION_NUMBER_BYTES32 = ethers.utils.formatBytes32String("1.0.0"); // <-- REPLACE THIS (e.g., ethers.utils.formatBytes32String("v1.2.3"))

    // 3. Deployment Name (string)
    const DEPLOYMENT_NAME_STRING = "Test"; // <-- REPLACE THIS

    // --- END CONFIGURATION ---

    if (ECOSYSTEM_REGISTRY_ADDRESS === "0xYourEcosystemRegistryContractAddressHere" || VERSION_NUMBER_BYTES32 === "0x..." || !DEPLOYMENT_NAME_STRING) {
        console.error("❌ Please fill in the placeholder variables (ECOSYSTEM_REGISTRY_ADDRESS, VERSION_NUMBER_BYTES32, DEPLOYMENT_NAME_STRING) in the script.");
        process.exit(1);
    }
    if (!ethers.utils.isAddress(ECOSYSTEM_REGISTRY_ADDRESS)) {
         console.error(`❌ Invalid ECOSYSTEM_REGISTRY_ADDRESS: ${ECOSYSTEM_REGISTRY_ADDRESS}`);
         process.exit(1);
    }
   

    console.log("🚀 Starting deployment script...");

    // Get the signer (account) to send the transaction
    const [deployer] = await ethers.getSigners();
    console.log(` Payer Account: ${deployer.address}`);
    console.log(` Connected Network: ${hre.network.name}`);

    // 1. Get the Diamond contract bytecode using the idiomatic Hardhat method
    console.log("\n Sretrieving Diamond bytecode...");
    let diamondBytecode;
    try {
        const diamondArtifact = await hre.artifacts.readArtifact("Diamond");
        diamondBytecode = diamondArtifact.bytecode;
        if (!diamondBytecode || diamondBytecode === '0x') {
            throw new Error("Bytecode is empty or invalid.");
        }
        console.log(`  ✅ Diamond bytecode retrieved successfully (length: ${diamondBytecode.length}).`);
    } catch (error) {
        console.error(`❌ Error retrieving Diamond artifact: ${error.message}`);
        console.error("   Ensure 'Diamond.sol' is compiled and the artifact exists.");
        process.exit(1);
    }

    // 2. Generate a random salt (uint256)
    // We use randomBytes for cryptographic randomness and convert to BigNumber
    const salt = ethers.BigNumber.from(ethers.utils.randomBytes(32));
    console.log(`🧂 Generated random salt: ${salt.toString()}`);

    // 3. Get the deployed EcosystemRegistry contract instance
    console.log(`\nℹ️ Connecting to EcosystemRegistry at ${ECOSYSTEM_REGISTRY_ADDRESS}...`);
    let ecosystemRegistry;
    try {
        // We need the ABI to interact with the contract
        const registryArtifact = await hre.artifacts.readArtifact("EcosystemRegistry");
        ecosystemRegistry = await ethers.getContractAt(
            registryArtifact.abi,
            ECOSYSTEM_REGISTRY_ADDRESS,
            deployer // Connect the signer to send transactions
        );
        console.log("  ✅ Connected to EcosystemRegistry.");
    } catch (error) {
        console.error(`❌ Error connecting to EcosystemRegistry or reading its artifact: ${error.message}`);
        console.error("   Ensure the contract address is correct for the target network and 'EcosystemRegistry.sol' is compiled.");
        process.exit(1);
    }

    // 4. Call the deployVersion function
    console.log("\n🚀 Calling deployVersion function with parameters:");
    console.log(`  Version (bytes32): ${VERSION_NUMBER_BYTES32}`);
    console.log(`  Name (string):     "${DEPLOYMENT_NAME_STRING}"`);
    console.log(`  Salt (uint256):    ${salt.toString()}`);
    console.log(`  Bytecode Length:   ${diamondBytecode.length}`);

    try {
        const tx = await ecosystemRegistry.deployVersion(
            VERSION_NUMBER_BYTES32,
            DEPLOYMENT_NAME_STRING,
            salt,
            diamondBytecode
            // Optional: Add gas limit or price if needed
            // { gasLimit: 1_000_000 }
        );

        console.log(`\n Tx sent! Hash: ${tx.hash}`);
        console.log("   Waiting for transaction confirmation...");

        // Wait for the transaction to be mined (1 confirmation)
        const receipt = await tx.wait();

        console.log(`\n✅ Transaction confirmed!`);
        console.log(`   Block number: ${receipt.blockNumber}`);
        console.log(`   Gas used: ${receipt.gasUsed.toString()}`);
        // You might want to check receipt.events here if deployVersion emits any useful events

    } catch (error) {
        console.error(`❌ Error calling deployVersion: ${error.message}`);
        // Log more details if available (e.g., revert reason)
        if (error.data) {
            console.error(`   Error data: ${error.data}`);
        }
         if (error.reason) {
            console.error(`   Revert reason: ${error.reason}`);
        }
        process.exit(1);
    }

    console.log("\n🎉 Script finished successfully!");
}

// Standard Hardhat script execution pattern
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("❌ Script failed:", error);
        process.exit(1);
    });