const { MerkleTree } = require('merkletreejs');
const { ethers } = require('hardhat');

// Define and export constants
const CURRENCY_DECIMALS = 18;
const CURRENCY_ID = 0;
const CONSUMPTION_ADDRESS = "0x0000000000000000000000000000000000000001"; 



/**
 * Creates a Merkle tree for off-chain allocations and returns the root and proofs.
 * @param {Array<object>} allocations - An array of allocation objects {user: string, purchaseId: number, amount: BigNumber}.
 * @returns {{root: string, allocationProofs: Array<object>}}
 */
function createOffChainMerkleTree(allocations) {
    const leaves = allocations.map(alloc => 
        ethers.utils.solidityKeccak256(
            ['address', 'uint256', 'uint256'],
            [alloc.user, alloc.purchaseId, alloc.amount]
        )
    );
    const tree = new MerkleTree(leaves, ethers.utils.keccak256, { sortPairs: true });
    const root = tree.getHexRoot();

    const allocationProofs = allocations.map(alloc => {
        const leaf = ethers.utils.solidityKeccak256(
            ['address', 'uint256', 'uint256'],
            [alloc.user, alloc.purchaseId, alloc.amount]
        );
        const proof = tree.getHexProof(leaf);
        return {
            leaf: {
                user: alloc.user,
                purchaseId: alloc.purchaseId,
                amount: alloc.amount,
            },
            proof: proof,
        };
    });

    return { root, allocationProofs };
}

/**
 * Generates mock data for CommunityOffering deployment scripts.
 * @param {{deployer: object, user1: object, user2: object, user3: object}} signers - Signer objects from ethers.
 * @param {{paymentToken: object, creatorToken: object}} tokens - Deployed token contracts.
 * @returns {object} - An object containing all mock data.
 */
async function getMockData(signers, tokens) {
    const { user1, user2, user3 } = signers;

    // --- Airdrop Data ---
    const airdropData = [
        { recipient: user1.address, amount: ethers.utils.parseUnits("500", CURRENCY_DECIMALS) },
        { recipient: user2.address, amount: ethers.utils.parseUnits("750", CURRENCY_DECIMALS) },
        { recipient: user3.address, amount: ethers.utils.parseUnits("1000", CURRENCY_DECIMALS) },
    ];

   

        const mockERC20InitialBalances =  {
            [user1.address.toLowerCase()]: ethers.utils.parseUnits("1000", CURRENCY_DECIMALS),
            [user2.address.toLowerCase()]: ethers.utils.parseUnits("500", CURRENCY_DECIMALS),
            [user3.address.toLowerCase()]: ethers.utils.parseUnits("2000", CURRENCY_DECIMALS),
        }

 
    // --- Define Off-Chain Allocations for Merkle Tree ---
    const offering1Allocations = [
        // User 2 has an off-chain allocation in the first offering
        { user: user2.address, purchaseId: 0, amount: ethers.utils.parseEther("1000") },
         { user: user3.address, purchaseId: 1, amount: ethers.utils.parseEther("500") }
    ];
    const { root: offering1Root, allocationProofs: offering1Proofs } = createOffChainMerkleTree(offering1Allocations);
    
    // --- Community Offering Parameters ---
    const communityOfferings = [
        {
            name: "Community Offering Alpha",
            merkleRoot: offering1Root,
            totalAvailableAmount: ethers.utils.parseEther("100000"), // Total CRT for sale
            maxAmountPerUser: ethers.utils.parseEther("5000"), // Max CRT per user for on-chain purchases
            ratio: 2, // Price: 2 MPT per 1 CRT
            offchainAllocations: offering1Proofs, // Used by the script to simulate claims
        },
        {
            name: "Community Offering Beta",
            merkleRoot: ethers.constants.HashZero, // No off-chain component for this one initially
            totalAvailableAmount: ethers.utils.parseEther("250000"),
            maxAmountPerUser: ethers.utils.parseEther("10000"),
            ratio: 3, // Price: 1.5 MPT per 1 CRT
            offchainAllocations: [],
        },
    ];

    // --- Data for Creator-Initiated Fulfillment ---
    const offchainFulfillmentData = {
        fundedUsers: [user3.address],
        offChainPurchaseIds: [0],
        amounts: [ethers.utils.parseEther("2500")]
    };

    return {
        CURRENCY_DECIMALS,
        communityOfferings,
        offchainFulfillmentData,
        CURRENCY_ID,
        mockERC20InitialBalances,
        airdropData,
        CONSUMPTION_ADDRESS
    };
}

module.exports = {
    getMockData,
};
