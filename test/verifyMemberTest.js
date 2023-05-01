const { expect } = require("chai");
const { ethers } = require("hardhat");
const { MerkleTree } = require('@openzeppelin/merkle-tree');

describe("Verifier", function () {
  let verifier;
  let root;
  let accounts;

  beforeEach(async function () {
    const Account = await ethers.getContractFactory("Verifier");
    accounts = [
      { addr: "0x1111111111111111111111111111111111111111", amount: 10 },
      { addr: "0x2222222222222222222222222222222222222222", amount: 20 },
      { addr: "0x3333333333333333333333333333333333333333", amount: 30 },
      { addr: "0x4444444444444444444444444444444444444444", amount: 40 }
    ];
    const leaves = accounts.map(account => {
      return keccak256(abi.encode(account.addr, account.amount));
    });
    const tree = new MerkleTree(leaves);
    root = tree.getRoot();
    verifier = await Account.deploy(root);
  });

  it("should verify the Merkle proof for a single account", async function () {
    const leaf = keccak256(abi.encode(accounts[0].addr, accounts[0].amount));
    const proof = tree.getProof(leaf);
    expect(await verifier.verify(proof, accounts[0].addr, accounts[0].amount)).to.equal(true);
  });

  it("should verify the Merkle proof for multiple accounts", async function () {
    const proofFlags = [true, false, true, true];
    const proof = proofFlags.map((flag, i) => {
      if (flag) {
        return tree.getProof(leaves[i]);
      }
      return [];
    });
    expect(await verifier.multiProofVerify(proof, proofFlags, accounts)).to.equal(true);
  });

  it("should fail to verify an invalid Merkle proof", async function () {
    const proof = tree.getProof(leaves[0]);
    expect(await verifier.verify(proof, accounts[1].addr, accounts[1].amount)).to.equal(false);
  });

  it("should fail to verify an invalid multiproof", async function () {
    const proofFlags = [true, false, true, true];
    const proof = proofFlags.map((flag, i) => {
      if (flag) {
        return tree.getProof(leaves[i]);
      }
      return [];
    });
    expect(await verifier.multiProofVerify(proof, proofFlags, accounts.slice(1))).to.equal(false);
  });
});
