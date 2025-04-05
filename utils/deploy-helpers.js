// In deploy-helpers.js

const { Interface } = require("@ethersproject/abi"); // Or from ethers v6

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

// Export the new function and potentially the modified getSelectors
module.exports = {
    // ... other existing helpers ...
    getSelectors, // Export modified helper if needed elsewhere
    createFacetCuts_RemoveOnlyDuplicates, // Export new function
    // Keep old createFacetCuts if needed, maybe rename it? Or remove if replaced.
    // createFacetCuts: oldCreateFacetCuts,
};