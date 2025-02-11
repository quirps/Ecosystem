import { Signer, ethers } from "ethers";
const { signTypedData } = require('@metamask/eth-sig-util')
export interface MetaTransaction {
    signer: string;
    target: string;
    paymasterData : string;
    targetData: string;
    gasLimit: BigInt;
    nonce: number;
    deadline: number; // Optional for paymaster validation
}

export class MetaTransactionFactory {
  private domainSeparator: string;
  private metaTxTypeHash: string;
  private appName : string;
  private version : string;
  private chainId: number;
  private trustedForwarderAddress: string;

  constructor(
    appName: string,
    version: string,
    chainId: number,
    trustedForwarderAddress: string,
  ) {
    this.appName = appName; 
    this.version = version;
    this.chainId = chainId;
    this.trustedForwarderAddress = trustedForwarderAddress;

    // Compute DOMAIN_SEPARATOR based on EIP-712
    this.domainSeparator = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        ["bytes32", "string", "string", "uint256","address"],
        [
          ethers.utils.keccak256(
            ethers.utils.toUtf8Bytes(
              "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
            )
          ),
          appName,
          version,
          chainId,
          trustedForwarderAddress,
        ]
      )
    );

    // Set the META_TX_TYPEHASH
    this.metaTxTypeHash = ethers.utils.keccak256(
      ethers.utils.toUtf8Bytes(
        "MetaTransaction(address signer,address target,bytes paymasterData,bytes targetData,uint256 gasLimit,uint256 nonce,uint32 deadline)"
      )
    );
  }

  /**
   * Generate a meta-transaction hash.
   * @param userAddress Address of the user authorizing the transaction.
   * @param target Address of the target contract.
   * @param data Encoded function call data.
   * @param gasLimit Gas limit for execution.
   * @param nonce Nonce for replay protection.
   * @returns Meta-transaction hash to sign (EIP-712 compliant).
   */
  public generateMetaTxHash(
    signer: string,
    target: string,
    paymasterData : string,
    targetData: string,
    gasLimit: BigInt,
    nonce: number, 
    deadline : number
  ): string {
    // Compute the struct hash for the meta-transaction
    const structHash = ethers.utils.keccak256(
      ethers.utils.defaultAbiCoder.encode(
        ["bytes32", "address", "address", "bytes", "bytes", "uint256", "uint256", "uint32"],
        [
          this.metaTxTypeHash,
          signer,
          target,
          paymasterData,
          targetData,
          gasLimit,
          nonce,
          deadline,
        ]
      )
    );

    // Final EIP-712 hash
    const metaTxHash = ethers.utils.keccak256(
      ethers.utils.solidityPack(
        ["string", "bytes32", "bytes32"],
        ["\x19\x01", this.domainSeparator, structHash]
      )
    );

    return metaTxHash;
  }

  /**
   * Create a full payload for the transaction, ready for signing.
   * @param signer Address of the user authorizing the transaction.
   * @param target Address of the target contract.
   * @param data Encoded function call data.
   * @param gasLimit Gas limit for execution.
   * @param nonce Nonce for replay protection.
   * @returns Object containing the meta-transaction hash and structured data.
   */
  public createMetaTransaction(
    signer: string,
    target: string,
    paymasterData : string,
    targetData: string,
    gasLimit: BigInt,
    nonce: number,
    deadline : number
  ) {
    const metaTxHash = this.generateMetaTxHash(
      signer,
      target,
      paymasterData,
      targetData,
      gasLimit,
      nonce,
      deadline,
    );

    return {
      metaTxHash,
      metaTxData: {
        signer,
        target,
        paymasterData,
        targetData,
        gasLimit,
        nonce,
        deadline,
      },
    };
  }

  async signMetaTransaction(
    domain : any,
    signer: any,
    metaTx: MetaTransaction
): Promise<string> {
    const types = {
        MetaTransaction: [
            { name: "signer", type: "address" },
            { name: "target", type: "address" },
            { name: "paymasterData", type:"bytes"},
            { name: "targetData", type: "bytes" },
            { name: "gasLimit", type: "uint256" },
            { name: "nonce", type: "uint256" },
            { name: "deadline", type: "uint32" },
        ],
    };

    const signature = await signer._signTypedData(
        {
            name: this.appName,
            version: this.version,
            verifyingContract: this.trustedForwarderAddress,
            chainId: this.chainId,
        },
        types,
        metaTx
    );

    return signature;
}
  /**
   * Verify if a signature matches the meta-transaction hash.
   * @param metaTxHash The hash of the meta-transaction.
   * @param signature The signature to verify.
   * @param expectedSigner The expected signer's address.
   * @returns True if the signature is valid, false otherwise.
   */
  public verifySignature(
    metaTxHash: string,
    signature: string,
    expectedSigner: any
  ): boolean {
    // Recover the address from the signature
    const recoveredAddress = ethers.utils.recoverAddress(metaTxHash, signature);

    // Compare the recovered address with the expected signer
    return recoveredAddress.toLowerCase() === expectedSigner.address.toLowerCase();
  }
}
