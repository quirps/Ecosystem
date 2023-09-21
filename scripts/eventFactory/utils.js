const ethers = require("ethers")
const maxUint160 = '0x' + 'f'.repeat(40);
function addressesToLeaves( ethereumAddresses ){
    ethereumAddresses.sort((a, b) => a.toLowerCase().localeCompare(b.toLowerCase()));
    const sortedEthereumAddresses = [ethers.constants.AddressZero, ...ethereumAddresses, maxUint160]
    const newArray = sortedEthereumAddresses.slice(0, -1).map((_, i) => [sortedEthereumAddresses[i], sortedEthereumAddresses[i + 1]]);
    console.log(newArray)
    return newArray
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
  
  exports.addressesToLeaves = addressesToLeaves
  