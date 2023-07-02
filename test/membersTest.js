//initialization - create a bouny address, set bounty currency id, set bounty max balance

const {
  getSelectors,
  FacetCutAction,
  removeSelectors,
  findAddressPositionInFacets
} = require('../scripts/libraries/diamond.js')
const { config } = require("hardhat");
const { generateMemberSignature } = require("../scripts/verification/member/generateMemberSignature.js")
const { deployDiamond } = require('../scripts/deploy.js')
const { expect } = require("chai");
const { ethers } = require('hardhat');
const hardhat = require('hardhat');


describe("Members", function () {
  let ERC1155;
  let ERC1155Transfer;
  let Members;
  let Moderator;

  let owner;
  let user;
  let moderator;
  let verificationSigner;

  let diamondAddress;
  let verificationPrivateKey;

  let bountyAddress;
  let bountyCurrencyId = 0;
  let bountyMaxBalance = 10;

  beforeEach(async function () {
    const accounts = config.networks.hardhat.accounts;
    const Wallet = ethers.Wallet.fromMnemonic(accounts.mnemonic)
    verificationSigner = Wallet.connect(ethers.provider);
    verificationPrivateKey = Wallet.privateKey;
    [owner, user, bountyAddress, moderator] = await ethers.getSigners();

    diamondAddress = await deployDiamond()
    diamondCutFacet = await ethers.getContractAt('DiamondCutFacet', diamondAddress)


    const ERC1155Factory = await ethers.getContractFactory("ERC1155");
    ERC1155 = await ERC1155Factory.deploy();
    diamondCut(ERC1155);

    const ERC1155TransferFactory = await ethers.getContractFactory("ERC1155Transfer");
    ERC1155Transfer = await ERC1155TransferFactory.deploy();
    diamondCut(ERC1155Transfer);


    const MembersFactory = await ethers.getContractFactory("Members");
    Members = await MembersFactory.deploy();
    diamondCut(Members);

    const ModeratorFactory = await ethers.getContractFactory("Moderator");
    Moderator = await ModeratorFactory.deploy();
    diamondCut(Moderator);

    Moderator = await ethers.getContractAt('Moderator', diamondAddress)
    ERC1155 = await ethers.getContractAt('ERC1155', diamondAddress)
    ERC1155Transfer = await ethers.getContractAt('ERC1155Transfer', diamondAddress)
    Members = await ethers.getContractAt('Members', diamondAddress)

    await ERC1155.mint(owner.address, bountyCurrencyId, 1000, "0x");
    await ERC1155Transfer.setApprovalForAll(diamondAddress, true);
    await Members.initialization(bountyAddress.address, bountyCurrencyId, bountyMaxBalance);

    let bounty = await Members.getBounty();
    console.log(3)
  });

  describe("Handles bounty tests", async function () {

    it("should revert on exceeding maxBounty and add bounty balance when below", async function () {
      let amount = 15;
      await expect(
        Members.connect(owner).addBountyBalance(amount))
        .revertedWith('BMB: New bounty balance exceeds bountyMaxBalance');

      amount = 5;
      await Members.connect(owner).addBountyBalance(amount)

      const balance = await ERC1155.balanceOf(bountyAddress.address, bountyCurrencyId);
      expect(balance).to.equal(amount);
    });

    it("should remove bounty balance", async function () {
      const amount = 5;
      await Members.connect(owner).addBountyBalance(amount);
      await Members.connect(owner).removeBountyBalance(amount);
      const balance = await ERC1155.balanceOf(bountyAddress.address, bountyCurrencyId);
      expect(balance).to.equal(0);
    });

    it("should set bounty currency id", async function () {
      const currencyId = 1;
      await Members.connect(owner).setBountyCurrencyId(currencyId);
      const bountyCurrencyId = (await Members.getBounty()).currencyId;
      expect(bountyCurrencyId).to.equal(currencyId);
    });

    it("should set bounty max balance", async function () {
      const maxBalance = 1000;
      await Members.connect(owner).setBountyMaxBalance(maxBalance);
      const bountyMaxBalance = (await Members.getBounty()).maxBalance;
      expect(bountyMaxBalance).to.equal(maxBalance);
    });

    it("should set bounty address", async function () {
      let bountyAddress = await user.address;
      await Members.connect(owner).setBountyAddress(bountyAddress);
      const currentBountyAddress = (await Members.getBounty()).bountyAddress;
      expect(currentBountyAddress).to.equal(bountyAddress);
    });

  })

  describe("Members", async function () {
    let v;
    let r;
    let s;
    let data;

    beforeEach(async function () {
      const network = await ethers.getDefaultProvider().getNetwork();
      console.log("Network chain id=", network.chainId);
      const chainId = await ethers.provider.getNetwork().then((network) => network.chainId);
       ( { v, r, s, data } = generateMemberSignature(diamondAddress, chainId, verificationSigner, verificationPrivateKey, 394, 200) )
      await Moderator.setModeratorRank(moderator.address, 220);
    })


    it("should set members via permissioned moderator, verifies stored leaves", async function () {
      let rankHistory;
      await Members.connect(moderator).setMembersRankPermissioned(data);

      rankHistory = await Members.callStatic.getUserRankHistory(data[0].memberAddress, 4); 
      console.log(3)
      let rankHistory0 = {rank:rankHistory[0].rank, timestamp : rankHistory[0].timestamp}
      expect(rankHistory0.rank).to.equal(data[0].memberRank.rank);
      expect(rankHistory0.timestamp).to.be.greaterThan(data[0].memberRank.timestamp);
      // Add assertions or further checks
    });

    it("should set leaves via signature", async function () {
      const nonce = 398;
      await Members.setMembersRanks(v, r, s, verificationSigner.address, nonce, data)
      
      // Add assertions or further checks
    });

    it("should create memberRankHIsory greater than 1 and verify chronioligical ordering of timestamps", async function () {
      const leaves = [
        // Add test data for the leaves parameter
      ];
      // Call the __changeMemberRanks function directly and perform necessary assertions
    });
  })

  // Add more test cases for the remaining internal functions...

});


async function diamondCut(contract) {
  const selectors = getSelectors(contract)
  tx = await diamondCutFacet.diamondCut(
    [{
      facetAddress: contract.address,
      action: FacetCutAction.Add,
      functionSelectors: selectors
    }],
    ethers.constants.AddressZero, '0x', { gasLimit: 800000 })
}