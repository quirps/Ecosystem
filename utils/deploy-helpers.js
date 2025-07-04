// In deploy-helpers.js

const { Interface } = require("@ethersproject/abi"); // Or from ethers v6
// deploy/utils/ticketUtils.js
const { ethers } = require("hardhat");

// Assume getSelectors returns [{selector: string, signature: string}]
function getSelectors(abi) {
    const iface = new Interface(abi);
    const selectors = [];
    // Use fragments which represent items in the ABI
    iface.fragments.forEach((fragment) => {
        if (fragment.type === "function") {
             // Reconstruct a basic signature string for logging/mapping
             const funcSig = fragment.name + "(" + fragment.inputs.map(i => i.type).join(',') + ")";
            selectors.push({
                 selector: iface.getSighash(fragment),
                 signature: funcSig // Store signature string
            });
        }
    });
    return selectors;
}


// New function
async function createFacetCuts_RemoveOnlyDuplicates(facetNames, deployments) {
    const { get } = deployments;
    const facetCuts = [];
    // Map to track selector origin: selectorHex => { facetName: string, functionSig: string }
    const selectorMap = {};
    const FacetCutAction = { Add: 0, Replace: 1, Remove: 2 }; // Standard Diamond actions

    console.log("--- Generating Facet Cuts (Duplicates Allowed Across Facets) ---");

    for (const facetName of facetNames) {
        let deployment;
        try {
            deployment = await get(facetName);
        } catch (error) {
             console.error(`   ERROR: Deployment artifact for facet "${facetName}" not found. Skipping.`);
             continue; // Skip this facet if deployment missing
        }

        const facetAddress = deployment.address;
        const facetAbi = deployment.abi;

        if (!facetAbi) {
             console.warn(`   WARN: ABI not found for facet "${facetName}". Skipping.`);
             continue;
        }

        const functionSelectorsData = getSelectors(facetAbi); // Get [{selector, signature}]
        const selectorsForThisCut = [];
        const seenSelectorsThisFacet = new Set(); // Track duplicates within the *same* facet

        if (functionSelectorsData.length === 0) {
            console.log(`   INFO: No external functions found for facet "${facetName}".`);
            continue;
        }

        console.log(`   Processing ${facetName} (${functionSelectorsData.length} selectors)...`);

        for (const { selector, signature } of functionSelectorsData) {
            if (seenSelectorsThisFacet.has(selector)) {
                // Should not happen with valid ABI, but good check
                console.warn(`      DEBUG: Duplicate selector ${selector} (${signature}) within ${facetName} ABI detected. Skipping addition.`);
                continue;
            }

            const existingRegistration = selectorMap[selector];
            if (existingRegistration) {
                // Clash detected with a DIFFERENT facet
                 console.warn(`      WARNING: Selector clash! ${selector} (${facetName}/${signature}) conflicts with previously registered selector from ${existingRegistration.facetName}/${existingRegistration.signature}. Including selector for ${facetName}.`);
                 // Still add the selector per user request
                 selectorsForThisCut.push(selector);
                 seenSelectorsThisFacet.add(selector);
                 // Update map to show latest registration (or store array if needed)
                 selectorMap[selector] = { facetName, signature };
            } else {
                // New selector
                selectorsForThisCut.push(selector);
                seenSelectorsThisFacet.add(selector);
                selectorMap[selector] = { facetName, signature };
            }
        }

        if (selectorsForThisCut.length > 0) {
            facetCuts.push({
                facetAddress: facetAddress,
                action: FacetCutAction.Add, // Always Add for initial setup
                functionSelectors: selectorsForThisCut,
            });
             console.log(`      Added cut for ${facetName} with ${selectorsForThisCut.length} selectors.`);
        }
    }
    console.log("--- Finished Generating Facet Cuts ---");
    return facetCuts;
}





/**
 * @notice Helper function to create structured parameters for ticket creation.
 * @dev Exposes all parameters directly in the function signature for easy developer viewing,
 * aligning with a Solidity Constraints struct where most active flags are implicit.
 * @param name The name of the ticket. Defaults to "Default Ecosystem Ticket".
 * @param symbol The symbol of the ticket. Defaults to "ECOT".
 * @param uri The URI for the ticket's metadata. Defaults to "ipfs://default_ticket_metadata_uri".
 * @param isTransferrable Set to true if the ticket is transferable, false otherwise. Defaults to true.
 * @param isMembershipLevelActive Set to true to activate the minimum membership level constraint. Defaults to false.
 * @param minimumLevel If isMembershipLevelActive is true, the minimum member level required. Defaults to 0.
 * @param expireTime The Unix timestamp when the ticket expires. Set to 0 for no expiration. Defaults to 0.
 * @param fee The royalty fee amount. Set to 0 for no fee. Defaults to 0.
 * @returns An object containing the structured ticketMeta and constraints for Solidity.
 */
const createTicketParams = (
    title = "Default Ecosystem Ticket",
    description = "ECOT",
    imageHash = "sdfhishdfishfhsdhufishf",
    isTransferable = true, // Directly maps to Solidity's isTransferable
    isMembershipLevelActive = false, // Explicit active flag for membership level
    minimumLevel = 0, // Directly maps to Solidity's minimumMembershipLevel
    expireTime = 0, // Directly maps to Solidity's expireTime
    fee = 0 // Directly maps to Solidity's fee
) => {
    const ticketMeta = {
        title,
        description,
        imageHash,
    };

    // Aligning with the new Solidity struct:
    // struct Constraints {
    //     bool isTransferable;
    //     int64 minimumMembershipLevel;
    //     bool isMembershipLevelActive;
    //     uint32 expireTime;
    //     uint24 fee;
    // }
    const constraints = {
        isTransferable: isTransferable,
        minimumMembershipLevel: minimumLevel,
        isMembershipLevelActive: isMembershipLevelActive,
        expireTime: expireTime,
        royaltyFee: fee,
    };

    return {
        ticketMeta: ticketMeta,
        constraints: constraints,
    };
};



// Export the new function and potentially the modified getSelectors
module.exports = {
    // ... other existing helpers ...
    getSelectors, // Export modified helper if needed elsewhere
    createFacetCuts_RemoveOnlyDuplicates, // Export new function
    createTicketParams,
    // Keep old createFacetCuts if needed, maybe rename it? Or remove if replaced.
    // createFacetCuts: oldCreateFacetCuts,
};