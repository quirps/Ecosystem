const { ethers } = require('hardhat');
const yaml = require('js-yaml');
const fs = require('fs');

let CONFIG;
// Get document, or throw exception on error
try {
  CONFIG = yaml.load(fs.readFileSync('/home/joe/Documents/EcoSystem1/ERC1155Config.yml', 'utf8'));
  console.log(CONFIG);
} catch (e) {
  console.log(e);
}

/// fund ether to users
/// deploy erc1155
/// fund each user with corresponding confugration parameters

async function ERC1155Config(operator,erc1155, erc1155Transfer) {
  let signers = await ethers.getSigners()
  let provider = ethers.provider
  let balance = await provider.getBalance(signers[0].address)
  let erc1155Address;
  
  //default balances 10^22

  // let _erc1155 = await ethers.getContractFactory("ERC1155Mock");
  // erc1155 = await _erc1155.deploy()
  

  await configureUsers(erc1155, erc1155Transfer, operator)

  return await erc1155.address 
  console.log(2)
}




async function configureUsers(erc1155,erc1155Transfer, operator) {
  let signers = await ethers.getSigners()
  for (let i=0; i < CONFIG.numUsers; i++) {
    let ids = [0,1,2,3]
    let amounts = CONFIG.users[i]
    let signer = signers[i]
    await erc1155.mintBatch(signer.address, ids, amounts, "0x00" )
    await erc1155Transfer.connect(signer).setApprovalForAll(operator,true)
  }
  console.log(3)
}


module.exports = {ERC1155Config}