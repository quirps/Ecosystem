const { ethers } = require('hardhat');

// Define and export constants
const CURRENCY_DECIMALS = 18;
const CURRENCY_ID = 0;
// Address used as the "Consumption" sink for token burns
const CONSUMPTION_ADDRESS = "0x0000000000000000000000000000000000000001"; 

/**
 * Generates mock data for Ecosystem token setup and burn simulation.
 * @param {{deployer: object, user1: object, user2: object, user3: object}} signers - Signer objects from ethers.
 * @param {{ecosystemDiamond: object}} deployments - Deployed contract objects.
 * @returns {object} - An object containing all mock data.
 */
function getMockData(signers, deployments) {
    // Note: The signers must be passed with the keys 'user1', 'user2', 'user3', etc., 
    // where the value is the Ethers Signer object.
    const { user1, user2, user3 } = signers;

    // --- Airdrop Data ---
    const airdropData = [
        { recipient: user1.address, amount: ethers.utils.parseUnits("500", CURRENCY_DECIMALS) },
        { recipient: user2.address, amount: ethers.utils.parseUnits("750", CURRENCY_DECIMALS) },
        { recipient: user3.address, amount: ethers.utils.parseUnits("1000", CURRENCY_DECIMALS) },
    ];

    // Note: All community offering, Merkle tree, and payment token data has been removed per request.

    return {
        CURRENCY_DECIMALS,
        CURRENCY_ID,
        airdropData,
        CONSUMPTION_ADDRESS
    };
}

module.exports = {
    getMockData,
};
