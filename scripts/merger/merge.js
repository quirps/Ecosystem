const { merge } = require('sol-merger');
const fs = require('fs');
async function main() {
    // Get the merged code as a string
    const mergedCode = await merge('./contracts/facets/Minimal.sol');
    // Print it out or write it to a file etc.
    console.log(mergedCode);
    fs.writeFileSync("./Members.txt",mergedCode)
}

main()