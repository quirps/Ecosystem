const ethers = require('ethers')
const {generateMemberSignature} = require('./generateMemberSignature')


async function main() {
    const Wallet = ethers.Wallet.createRandom()
    //verificationSigner = Wallet.connect(ethers.provider);
    // verificationPrivateKey = Wallet.privateKey;
    
    let verificationAddress = "0xddaAd340b0f1Ef65169Ae5E41A8b10776a75482d"
    const { s, v, r, data } = generateMemberSignature(verificationAddress, 1, Wallet,Wallet.privateKey , 399, 2)
    console.log(`s - ${s} /n v - ${v} /n r - ${r} /n data - ${data} /n`)
    console.log("Wallet Address - ", Wallet.address)
}

main()