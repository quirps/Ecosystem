const ethers = require("ethers")
const {StandardMerkleTree} = require("@openzeppelin/merkle-tree")
const fs = require('fs')


const maxUint160 = '0x' + 'f'.repeat(40);

function addressesToLeaves( ethereumAddresses ){
    ethereumAddresses.sort((a, b) => a.toLowerCase().localeCompare(b.toLowerCase()));
    const sortedEthereumAddresses = [ethers.constants.AddressZero, ...ethereumAddresses, maxUint160]
    const newArray = sortedEthereumAddresses.slice(0, -1).map((_, i) => [sortedEthereumAddresses[i], sortedEthereumAddresses[i + 1]]);
    console.log(newArray)
    return newArray
}
function addressGreaterEqualTo(a,b){
  return a.toLowerCase().localeCompare(b.toLowerCase()) >= 0;
}
function getBoundingLeaf(address, tree){
  for (const [_, leaf] of tree.entries()) {
    if ( addressGreaterEqualTo( address, leaf[0] ) &&  !addressGreaterEqualTo(address, leaf[1]) ) {
      // (3)
      return leaf
    }
  }
}

function generateMerkleTree(values){
    const tree = StandardMerkleTree.of(values, ["address", "address"]);
    return tree;
}
function generateProof(tree, value){
    for (const [i, v] of tree.entries()) {
        if (v[0] === value[0]) {
          // (3)
          const proof = tree.getProof(i);
          console.log('Value:', v);
          console.log('Proof:', proof);
          return proof
        }
      }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
    const addresses = []
    for(let i = 0; i < 20; i++){
        addresses.push( new ethers.Wallet.createRandom().address)
    }
    addressesToLeaves(addresses)
      .then(() => process.exit(0))
      .catch(error => {
        console.error(error)
        process.exit(1)
      })
  }
  

  module.exports = {generateMerkleTree, addressesToLeaves, generateProof, getBoundingLeaf}