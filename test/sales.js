const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Sales Contract", function () {
    let SalesContract, salesContract, owner, addr1, addr2;
  
    beforeEach(async () => {
      SalesContract = await ethers.getContractFactory("Sales");
      [owner, addr1, addr2] = await ethers.getSigners();
      salesContract = await SalesContract.deploy(addr1.address); // Pass the ERC1155 contract address here
    });
  
    describe("createTieredSales", function () {
      it("Should create tiered sales successfully", async function () {
        const salesInputs = [
          {
            startTime: 1,
            endTime: 2,
            rankRequired: 1,
            limit: 1,
            itemIds: [1],
            itemAmounts: [1],
            paymentTokenAddress: addr2.address, // Pass ERC20 contract address here
          },
          {
            startTime: 3,
            endTime: 4,
            rankRequired: 2,
            limit: 2,
            itemIds: [2],
            itemAmounts: [2],
            paymentTokenAddress: addr2.address, // Pass ERC20 contract address here
          },
        ];
  
        await salesContract.connect(owner).createTieredSales(salesInputs);
        expect(await salesContract.salesCounter()).to.equal(2);
      });
    });
  });

  describe("Sales Contract", function () {
    let SalesContract, salesContract, owner, addr1, addr2, ERC20Contract, ERC1155Contract;
  
    beforeEach(async () => {
  
      ERC1155Contract = await ethers.getContractFactory("ERC1155Transfer");
      erc1155 = await ERC1155Contract.deploy();
        
      ERC20Contract = await ethers.getContractFactory("MockERC20");
      erc20 = await ERC20Contract.deploy(erc1155.address);
  

      // Deploy SalesContract
      SalesContract = await ethers.getContractFactory("Sales");
      [owner, addr1, addr2] = await ethers.getSigners();
      salesContract = await SalesContract.deploy(erc1155.address);
  
      // Setup initial sale and rank
      await salesContract.connect(owner).createTieredSales([{
        startTime: Math.floor(Date.now() / 1000) - 100,
        endTime: Math.floor(Date.now() / 1000) + 100,
        rankRequired: 1,
        limit: 2,
        itemIds: [1],
        itemAmounts: [1],
        paymentTokenAddress: erc20.address,
      }]);
      await salesContract.connect(owner).memberRank(addr1.address, 1);
    });
  
    describe("buyItems", function () {
      it("Should allow buying items successfully", async function () {
        // Approve the SalesContract to spend addr1's ERC20 tokens
        await erc20.connect(addr1).approve(salesContract.address, ethers.utils.parseEther("1"));
  
        // Attempt to buy 1 item
        await salesContract.connect(addr1).buyItems(1, 1);
  
        // Verify the purchase was successful
        expect(await erc20.balanceOf(owner.address)).to.equal(ethers.utils.parseEther("1"));
        expect(await salesContract.saleStats(1, addr1.address)).to.equal(1);
      });
    });
  });