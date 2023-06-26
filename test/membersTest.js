//initialization - create a bouny address, set bounty currency id, set bounty max balance

const {
  getSelectors,
  FacetCutAction,
  removeSelectors,
  findAddressPositionInFacets
} = require('../scripts/libraries/diamond.js')
const { deployDiamond } = require('../scripts/deploy.js')
const { expect } = require("chai");
const { ethers } = require('hardhat');
describe("Members", function () {
  let ERC1155;
  let ERC1155Transfer;
  let Members;
  let owner;
  let user;
  let diamondAddress;

  let bountyAddress;
  let bountyCurrencyId = 0;
  let bountyMaxBalance = 10;

  beforeEach(async function () {

    [owner, user, bountyAddress] = await ethers.getSigners();

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

    ERC1155 = await ethers.getContractAt('ERC1155', diamondAddress)
    ERC1155Transfer = await ethers.getContractAt('ERC1155Transfer', diamondAddress)
    Members = await ethers.getContractAt('Members', diamondAddress)

    await ERC1155.mint(owner.address, bountyCurrencyId, 1000, "0x");
    await ERC1155Transfer.setApprovalForAll(diamondAddress, true);
    await Members.initialization(bountyAddress.address, bountyCurrencyId, bountyMaxBalance);

  });

  describe("Handles bounty tests", async function () {

    it("should add bounty balance", async function () {
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
      const amount = 100;
      await Members.connect(owner).addBountyBalance(amount);
      await Members.connect(owner).removeBountyBalance(amount);
      const balance = await Members.bountyBalance();
      expect(balance).to.equal(0);
    });

    it("should set bounty currency id", async function () {
      const currencyId = 1;
      await Members.connect(owner).setBountyCurrencyId(currencyId);
      const bountyCurrencyId = await Members.bountyCurrencyId();
      expect(bountyCurrencyId).to.equal(currencyId);
    });

    it("should set bounty max balance", async function () {
      const maxBalance = 1000;
      await Members.connect(owner).setBountyMaxBalance(maxBalance);
      const bountyMaxBalance = await Members.bountyMaxBalance();
      expect(bountyMaxBalance).to.equal(maxBalance);
    });

    it("should set bounty address", async function () {
      const bountyAddress = await user.getAddress();
      await Members.connect(owner).setBountyAddress(bountyAddress);
      const currentBountyAddress = await Members.bountyAddress();
      expect(currentBountyAddress).to.equal(bountyAddress);
    });

  })

  describe("Members", async function () {


    it("should set members rank permissioned", async function () {
      const leaves = [
        // Add test data for the leaves parameter
      ];
      await Members.connect(owner).setMembersRankPermissioned(leaves);
      // Add assertions or further checks
    });

    it("should set members ranks", async function () {
      const proof = [
        // Add test data for the proof parameter
      ];
      const proofFlags = [
        // Add test data for the proofFlags parameter
      ];
      const leaves = [
        // Add test data for the leaves parameter
      ];
      await Members.connect(owner).setMembersRanks(proof, proofFlags, leaves);
      // Add assertions or further checks
    });

    it("should change member ranks", async function () {
      const leaves = [
        // Add test data for the leaves parameter
      ];
      // Call the __changeMemberRanks function directly and perform necessary assertions
    });
  })

  // Add more test cases for the remaining internal functions...

});


async function diamondCut(contract){
  const selectors = getSelectors(contract)
    tx = await diamondCutFacet.diamondCut(
      [{
        facetAddress: contract.address,
        action: FacetCutAction.Add,
        functionSelectors: selectors
      }],
      ethers.constants.AddressZero, '0x', { gasLimit: 800000 })
}