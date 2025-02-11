const { TxFactory } = require("./txGeneratorFinal")
const { Swap, Target, Ecosystems } = require('../../deploy/attach/attatchments')
const {generateEthSwapPair} = require('../../deploy/swap/swapDeploy')
const {  artifacts ,ethers} = require('hardhat')
const BN = require('bn.js')
const { hashTypedData, createWalletClient, custom, http} = require('viem')
const sigUtil = require('eth-sig-util')

async function main(){
    // example verify
    const ExampleVerify = await ethers.getContractFactory("ExampleVerify")
    const exampleVerify = await ExampleVerify.deploy();

    const swap = await Swap();
    const ecosystems = await Ecosystems();
    // 
    const txGenerator = new TxFactory(exampleVerify.address);
    //set the domain
    await txGenerator.initializeDomain();
    //generate swap order data to transact to paymaster
    const { swapInit, swapConsumeRaw } = await generateEthSwapPair(
        swap,
        ecosystems[0].address
      );
    
    const paymasterData = await paymasterCallData(swap.address, swapConsumeRaw)
    
    //generate target data
    const targetAmount = 40;
    const targetData = await targetCallData( targetAmount )
    const gasLimit = BigInt("1000000000000000000") //1 eth
    const nonce = 1;
    const deadline = Math.floor( Date.now()/1000 + 5 * 60 ) //expires in 5 minutes

    //get target address 
    const target = await Target()
    const targetAddress = target.address
    
    //get signer
    //const signer = ( await ethers.getSigners() ) [10]
    let signer = await ethers.Wallet.createRandom()

    let privKeyBytes = ethers.utils.arrayify(signer.privateKey)
    const signerAddress = signer.address

    //ethers signed method
    const message = {
        signer : signerAddress,
        target : targetAddress, 
        paymasterData,
        targetData,
        gasLimit,
        nonce,
        deadline
    }
    //generate signature
    //const {signature, hash} = txGenerator.signMessage( privKeyBytes, message )
    //ethers signed method
    const { signature } = txGenerator.signMessage(privKeyBytes, message)
    const {v,r,s} =  ethers.utils.splitSignature(signature)

    const exampleBool = await exampleVerifyDeploy( exampleVerify, message, v, r, s)
    console.log(exampleBool)


}   

main()

async function paymasterCallData(swapAddress, swapOrder) {
    const artifact = await artifacts.readArtifact("Paymaster");
    const abi = artifact.abi;
  
    const IPaymaster = new ethers.utils.Interface(abi);
    const callData = IPaymaster.encodeFunctionData("swapRelay", [
      swapAddress,
      ...swapOrder,
    ]);
    console.log(`paymaster data ${callData}`);
    return callData;
  }
  
  async function targetCallData(amount) {
    const artifact = await artifacts.readArtifact("Target");
    const abi = artifact.abi;
  
    const ITarget = new ethers.utils.Interface(abi);
    const callData = ITarget.encodeFunctionData("storeData", [amount]);
    console.log(`target data - ${callData}`);
    return callData;
  }



async function exampleVerifyDeploy(verifyContract, message, v, r, s){
   
    const result = await verifyContract.callStatic.executeSetIfSignatureMatch(message, v, r, s) 
    return result
}



  
 