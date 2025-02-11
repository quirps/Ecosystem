const {ethers} = require('hardhat')
import { SimpleMetaTransactionFactory } from "./simpleGenerator";

const factory = new SimpleMetaTransactionFactory(
    "MyDApp", // App name
    "1.0", // Version
    "0x2D08BDf3c61834F76Decaf6E85ffAecFeF02E605", // Verifying contract
    1 // Chain ID (e.g., Ethereum Mainnet)
  );
  
  
  (async () => {
      const metaTx = { signer: "0x3AA4900eE07d95259c93871B2b313Af2c6eA8c8C" };
      
      const signer = await ethers.Wallet.createRandom(); // Example signer

      const signature = await factory.signMetaTransaction(signer, metaTx);
      console.log("Signature:", signature);
      
    const isValid = factory.verifySignature(metaTx, signature);
    console.log("Signature valid:", isValid);
  })();
  