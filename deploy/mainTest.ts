const {ethers} = require("hardhat")
const fromAddress = "0xa4fbDF500D758aDa4Ca6F9a01FA5b3Dc6566800F"

export async function main(){
    const [preFundedSigner] = await ethers.getSigners(); // Use first pre-funded account

    const tx = await preFundedSigner.sendTransaction({
      to: fromAddress, // The sender account in your task
      value: ethers.utils.parseEther("1000"), // Fund with 1000 ETH
    });

    await tx.wait();
    console.log(`Funded sender account with 1000 ETH in tx: ${tx.hash}`);
}

main()