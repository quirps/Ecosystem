const fs = require("fs");
const path = require("path");
const relativeVersionPath = "C:\\Users\\Joe\\Documents\\ActiveProjects\\Ecosystem\\deploy\\ecosystem\\versions";
/**
 * Combines ABIs from specified facets into a single ABI for diamond architecture.
 */
task("combine-abi", "Combines ABIs from specified facets into a single ABI")
  .addParam("versionfilename", "Comma-separated list of facet contract names")
  .addOptionalParam("outputfile", "The output file for the combined ABI", "./artifacts/DiamondCombinedABI.json")
  .setAction(async ({ versionfilename, outputfile }, hre) => {
    let combinedABI = [];
    let signatures = new Set();
    let versionFilePath;

    versionFilePath = path.join(relativeVersionPath, versionfilename)
    console.log(versionFilePath)
    const { facets } = require(versionFilePath);

    for (const facetName of facets) {
      try {
        // Fetch artifact for the facet
        const artifact = await hre.artifacts.readArtifact(facetName);
        const facetABI = artifact.abi;

        for (const item of facetABI) {
          // Generate a unique signature to avoid duplicates
          const signature = item.name + (item.inputs ? JSON.stringify(item.inputs) : "[]");

          if (!signatures.has(signature)) {
            combinedABI.push(item);
            signatures.add(signature);
          }
        }
      } catch (error) {
        console.error(`Error reading artifact for facet ${facetName}:`, error.message);
      }
    }

    // Write the combined ABI to the specified output file
    fs.writeFileSync(outputfile, JSON.stringify(combinedABI, null, 2));
    console.log(`Combined ABI written to ${outputfile}`);
  });

module.exports = {};
