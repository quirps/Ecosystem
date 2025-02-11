/**
 * Test relay as we upgrade the features
 */

/**
 * 1. Paymaster is a mere relay to the swap, assert it transacts the proper amount of ether.
 *    Vanilla verifier
 *    Assert target is properly changed.
 */

const { ethers, artifacts } = require("hardhat");
import { MetaTransactionFactory } from "./txGenerator";
import {
  Relay,
  TrustedForwarder,
  Paymaster,
  Swap,
  Ecosystems,
  Target,
} from "../deploy/attach/attatchments";

import { generateEthSwapPair } from "../deploy/swap/swapDeploy";

const TARGET_STORE_AMOUNT = 50;


async function vanillaRelayTest() {
  const paymaster = await Paymaster();
  const swap = await Swap();
  const ecosystems = await Ecosystems();
  const trustedForwarder = await TrustedForwarder();
  const target = await Target();

  const signers = await ethers.getSigners();
  const metaTxSigner = await signers[10];

  const metaTxFactory = new MetaTransactionFactory(
    "MassDX",
    "1.0.0",
    31337,
    trustedForwarder.address,
  );

  //verify

  const { swapInit, swapConsumeRaw } = await generateEthSwapPair(
    swap,
    ecosystems[0].address
  );

  console.log("Swap eth init");
  await swapInit;

  console.log("create paymaster data from swap eth consume");
  const paymasterData = await paymasterCallData(swap.address, swapConsumeRaw);

  console.log("create target data");
  const targetData = await targetCallData(TARGET_STORE_AMOUNT);

  const { metaTxHash, metaTxData } = metaTxFactory.createMetaTransaction(
    await metaTxSigner.getAddress(),
    target.address,
    paymasterData,
    targetData,
    BigInt(1000000000000000000),  
    1, 
    Math.floor ( Date.now()/ 1000 + 5000 )  
  );
  
  const DOMAIN = {name :"MassDX",
    version : "1.0.0",
    chainId : 31337,
    verifyingContract : trustedForwarder.address,
  }
  const signature = await metaTxFactory.signMetaTransaction(DOMAIN, metaTxSigner, metaTxData); 
  console.log(metaTxFactory.verifySignature( metaTxHash, signature, metaTxSigner) );
}
vanillaRelayTest();

async function paymasterCallData(swapAddress: string, swapOrder: any) {
  const artifact = await artifacts.readArtifact("Paymaster");
  const abi = artifact.abi;

  const IPaymaster = new ethers.utils.Interface(abi);
  const callData = IPaymaster.encodeFunctionData("swapRelay", [
    swapAddress,
    ...swapOrder,
  ]);
  console.log(callData);
  return callData;
}

async function targetCallData(amount: number) {
  const artifact = await artifacts.readArtifact("Target");
  const abi = artifact.abi;

  const ITarget = new ethers.utils.Interface(abi);
  const callData = ITarget.encodeFunctionData("storeData", [amount]);
  console.log(callData);
  return callData;
}
