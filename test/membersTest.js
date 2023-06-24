// SPDX-License-Identifier: MIT
const { ethers } = require("hardhat");
const { expect } = require("chai");

describe("iMembers", function () {
  let iMembers;
  let membersContract;

  beforeEach(async function () {
    iMembers = await ethers.getContractFactory("Members");
    membersContract = await iMembers.deploy();
    await membersContract.deployed();
  });

  it("should change rank labels", async function () {
    const oldRankLabels = ["Rank1", "Rank2"];
    const newRankLabels = ["NewRank1", "NewRank2"];

    await membersContract._changeRankLabels(oldRankLabels, newRankLabels);

    expect(await membersContract.rank("Rank1")).to.equal(0);
    expect(await membersContract.rank("Rank2")).to.equal(0);
    expect(await membersContract.rank("NewRank1")).to.equal(1);
    expect(await membersContract.rank("NewRank2")).to.equal(2);
  });

  it("should get user rank history", async function () {
    const user = ethers.constants.AddressZero;
    const rankLabel = "Rank1";
    const memberRank = { timestamp: ethers.BigNumber.from(Date.now()), rankLabel };
    await membersContract.memberRankHistory(user).push(memberRank);

    const userRankHistory = await membersContract._getUserRankHistory(user);

    expect(userRankHistory.length).to.equal(1);
    expect(userRankHistory[0].rankLabel).to.equal(rankLabel);
  });

  it("should get user rank label", async function () {
    const user = ethers.constants.AddressZero;
    const rankLabel = "Rank1";
    const memberRank = { timestamp: ethers.BigNumber.from(Date.now()), rankLabel };
    await membersContract.memberRankHistory(user).push(memberRank);

    const userRankLabel = await membersContract._getUserRankLabel(user);

    expect(userRankLabel).to.equal(rankLabel);
  });

  it("should get user rank", async function () {
    const user = ethers.constants.AddressZero;
    const rankLabel = "Rank1";
    const memberRank = { timestamp: ethers.BigNumber.from(Date.now()), rankLabel };
    await membersContract.memberRankHistory(user).push(memberRank);
    await membersContract.rank(rankLabel);

    const userRank = await membersContract._getUserRank(user);

    expect(userRank).to.equal(await membersContract.rank(rankLabel));
  });

  it("should change ranks", async function () {
    const rankLabels = ["Rank1", "Rank2"];
    const ranks = [1, 2];
    const deleteFlags = [false, false];
    const indices = [0, 1];

    await membersContract._changeRanks(rankLabels, ranks, deleteFlags, indices);

    expect(await membersContract.rank(rankLabels[0])).to.equal(ranks[0]);
    expect(await membersContract.rank(rankLabels[1])).to.equal(ranks[1]);
    expect(await membersContract.rankLabels(0)).to.equal(rankLabels[0]);
    expect(await membersContract.rankLabels(1)).to.equal(rankLabels[1]);
  });

  it("should set member rank permissioned", async function () {
    const members = [ethers.constants.AddressZero, ethers.constants.AddressZero];
    const rankLabels = ["Rank1", "Rank2"];

    await membersContract._setMemberRankPermissioned(members, rankLabels);

    const member1History = await membersContract.memberRankHistory(members[0]);
    const member2History = await membersContract.memberRankHistory(members[1]);

    expect(member1History.length).to.equal(1);
    expect(member1History[0].rankLabel).to.equal(rankLabels[0]);
    expect(member2History.length).to.equal(1);
    expect(member2History[0].rankLabel).to.equal(rankLabels[1]);
  });

  it("should set members ranks", async function () {
    const proof = [];
    const proofFlags = [];
    const leaves = [];

    const memberAddress = ethers.constants.AddressZero;
    const timestampLastUpdated = ethers.BigNumber.from(Date.now());
    const rankLabel = "Rank1";
    const memberRank = { timestamp: timestampLastUpdated, rankLabel };
    await membersContract.memberRankHistory(memberAddress).push(memberRank);

    const leaf = {
      memberAddress,
      timestampLastUpdated,
      rankLabel,
    };
    leaves.push(leaf);

    await membersContract._setMembersRanks(proof, proofFlags, leaves);

    const userRankLabel = await membersContract._getUserRankLabel(memberAddress);

    expect(userRankLabel).to.equal(rankLabel);
  });

  it("should add bounty balance", async function () {
    const amount = ethers.utils.parseEther("1");

    await membersContract.addBountyBalance(amount);

    const bountyBalance = 0; // set the expected bounty balance
    expect(await membersContract.getBountyBalance()).to.equal(bountyBalance);
  });

  it("should remove bounty balance", async function () {
    const amount = ethers.utils.parseEther("1");

    await membersContract.removeBountyBalance(amount);

    const bountyBalance = 0; // set the expected bounty balance
    expect(await membersContract.getBountyBalance()).to.equal(bountyBalance);
  });

  it("should set bounty currency id", async function () {
    const currencyId = 123;

    await membersContract.setBountyCurrencyId(currencyId);

    expect(await membersContract.bountyCurrencyId()).to.equal(currencyId);
  });

  it("should set bounty max balance", async function () {
    const maxBalance = ethers.utils.parseEther("100");

    await membersContract.setBountyMaxBalance(maxBalance);

    expect(await membersContract.bountyMaxBalance()).to.equal(maxBalance);
  });

  it("should set bounty address", async function () {
    const bountyAddress = ethers.constants.AddressZero;

    await membersContract.setBountyAddress(bountyAddress);

    expect(await membersContract.bountyAddress()).to.equal(bountyAddress);
  });
});
