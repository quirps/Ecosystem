const {StandardMerkleTree} = require("@openzeppelin/merkle-tree")
const fs = require('fs')
// (1)

function generateMerkleRoot(values){
    const tree = StandardMerkleTree.of(values, ["address", "address"]);
    return tree.root;
// (3)
console.log('Merkle Root:', tree.root);

// (4)
//fs.writeFileSync("tree.json", JSON.stringify(tree.dump()));
}
