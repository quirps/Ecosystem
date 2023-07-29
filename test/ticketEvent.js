const { expect } = require("chai");
const { ethers } = require("hardhat");
const { deployDiamond } = require('../scripts/deploy.js')
const { deployFacet } = require('../scripts/deployFacet.js')

describe("EventFactory", function () {
    let diamondAddress, EventFactory, eventFactory, erc1155Transfer, erc1155, owner, addr1, addr2;

    beforeEach(async function () {
        diamondAddress = await deployDiamond();
        // balance of signer
        // const provider = ethers.provider;
        // const balance = await provider.getBalance(users[0].address);
        let ERC1155CallData = "0x"
        await deployFacet(["ERC1155"], diamondAddress, ethers.constants.AddressZero, ERC1155CallData);
        await deployFacet(["ERC1155Transfer"], diamondAddress, ethers.constants.AddressZero, ERC1155CallData);
        await deployFacet(["EventFactory"], diamondAddress, ethers.constants.AddressZero, ERC1155CallData);


        erc1155Facet = await ethers.getContractAt('IERC1155', diamondAddress)
        erc1155TransferFacet = await ethers.getContractAt('IERC1155Transfer', diamondAddress)
        eventFactoryFacet = await ethers.getContractAt("IEventFactory", diamondAddress);

        [owner, addr1, addr2, _] = await ethers.getSigners();


        erc1155TransferFacet.setApprovalForAll(eventFactoryFacet.address,true);
        await eventFactoryFacet.deployed();
    });

    it("Should create an event correctly", async function () {
        const eventId = 1;
        const startTime = Math.floor(Date.now() / 1000);
        const endTime = startTime + 10000;

        await eventFactoryFacet.createEvent(eventId, startTime, endTime);
        const event = await eventFactoryFacet.events(eventId);

        expect(event.startTime).to.equal(startTime);
        expect(event.endTime).to.equal(endTime);
        expect(event.isCancelled).to.equal(false);
    });

    it("Should not create an event if end time is not greater than start time", async function () {
        const eventId = 1;
        const startTime = Math.floor(Date.now() / 1000);
        const endTime = startTime - 100;

        await expect(eventFactoryFacet.createEvent(eventId, startTime, endTime)).to.be.revertedWith("End time must be greater than start time");
    });

    it("Should set token details correctly", async function () {
        const eventId = 1;
        const tokenId = 1;
        const limitPerUser = 10;
        const totalLimit = 100;

        await eventFactoryFacet.setTokenDetails(eventId, tokenId, limitPerUser, totalLimit);
        const tokenDetails = await eventFactoryFacet.tokenDetails(eventId, tokenId);

        expect(tokenDetails.limitPerUser).to.equal(limitPerUser);
        expect(tokenDetails.totalLimit).to.equal(totalLimit);
        expect(tokenDetails.currentTotal).to.equal(0);
    });

    it("Should not set token details if total limit is not greater or equal to limit per user", async function () {
        const eventId = 1;
        const tokenId = 1;
        const limitPerUser = 100;
        const totalLimit = 10;

        await expect(eventFactoryFacet.setTokenDetails(eventId, tokenId, limitPerUser, totalLimit)).to.be.revertedWith("Total limit must be greater or equal to limit per user");
    });
    // ... previous code

    it("Should submit tokens correctly", async function () {
        const eventId = 1;
        const tokenId = 1;
        const limitPerUser = 10;
        const totalLimit = 100;
        const submitAmount = 5;
        const startTime = Math.floor(Date.now() / 1000);
        const endTime = startTime + 10000;

        await eventFactoryFacet.createEvent(eventId, startTime, endTime);
        await eventFactoryFacet.setTokenDetails(eventId, tokenId, limitPerUser, totalLimit);

        // Assume you have an ERC1155 token deployed as `token` and the owner has approved the EventFactory
        // await token.safeTransferFrom(owner.address, eventFactoryFacet.address, tokenId, submitAmount, []);
        
        erc1155Facet.mint(owner.address, tokenId, submitAmount, "")
        erc1155TransferFacet.safeTransferFrom(owner.address, eventFactoryFacet.address, tokenId, submitAmount,"");

        await eventFactoryFacet.submitTokens(eventId, tokenId, submitAmount);

        const userTokens = await eventFactoryFacet.userTokens(eventId, tokenId, owner.address);
        const tokenDetails = await eventFactoryFacet.tokenDetails(eventId, tokenId);

        expect(userTokens).to.equal(submitAmount);
        expect(tokenDetails.currentTotal).to.equal(submitAmount);
    });

    it("Should not submit tokens if the event is not active", async function () {
        const eventId = 1;
        const tokenId = 1;
        const submitAmount = 5;
        const startTime = Math.floor(Date.now() / 1000) + 10000; // Starts in the future
        const endTime = startTime + 10000;

        await eventFactoryFacet.createEvent(eventId, startTime, endTime);

        await expect(eventFactoryFacet.submitTokens(eventId, tokenId, submitAmount)).to.be.revertedWith("The event is not active");
    });

    it("Should reimburse user correctly", async function () {
        const eventId = 1;
        const tokenId = 1;
        const limitPerUser = 10;
        const totalLimit = 100;
        const submitAmount = 5;
        const startTime = Math.floor(Date.now() / 1000);
        const endTime = startTime + 10000;

        await eventFactoryFacet.createEvent(eventId, startTime, endTime);
        await eventFactoryFacet.setTokenDetails(eventId, tokenId, limitPerUser, totalLimit);

        // Assume you have an ERC1155 token deployed as `token` and the owner has approved the EventFactory
        // await token.safeTransferFrom(owner.address, eventFactoryFacet.address, tokenId, submitAmount, []);

        await eventFactoryFacet.submitTokens(eventId, tokenId, submitAmount);
        await eventFactoryFacet.reimburseUser(eventId, tokenId, submitAmount);

        const userTokens = await eventFactoryFacet.userTokens(eventId, tokenId, owner.address);
        const tokenDetails = await eventFactoryFacet.tokenDetails(eventId, tokenId);

        expect(userTokens).to.equal(0);
        expect(tokenDetails.currentTotal).to.equal(0);
    });

    it("Should cancel event correctly", async function () {
        const eventId = 1;
        const startTime = Math.floor(Date.now() / 1000);
        const endTime = startTime + 10000;

        await eventFactoryFacet.createEvent(eventId, startTime, endTime);
        await eventFactoryFacet.cancelEvent(eventId);

        const event = await eventFactoryFacet.events(eventId);

        expect(event.isCancelled).to.equal(true);
    });

    it("Should not cancel event if it has already ended", async function () {
        const eventId = 1;
        const startTime = Math.floor(Date.now() / 1000) - 20000; // Starts in the past
        const endTime = startTime + 10000;

        await eventFactoryFacet.createEvent(eventId, startTime, endTime);

        await expect(eventFactoryFacet.cancelEvent(eventId)).to.be.revertedWith("The event has ended");
    });

    it("Should allow users to withdraw tokens after the event is cancelled", async function () {
        const eventId = 1;
        const tokenId = 1;
        const limitPerUser = 10;
        const totalLimit = 100;
        const submitAmount = 5;
        const startTime = Math.floor(Date.now() / 1000);
        const endTime = startTime + 10000;

        await eventFactoryFacet.createEvent(eventId, startTime, endTime);
        await eventFactoryFacet.setTokenDetails(eventId, tokenId, limitPerUser, totalLimit);

        // Assume you have an ERC1155 token deployed as `token` and the owner has approved the EventFactory
        // await token.safeTransferFrom(owner.address, eventFactoryFacet.address, tokenId, submitAmount, []);
        
        
        await eventFactoryFacet.submitTokens(eventId, tokenId, submitAmount);
        await eventFactoryFacet.cancelEvent(eventId);
        await eventFactoryFacet.withdrawTokens(eventId, tokenId);

        const userTokens = await eventFactoryFacet.userTokens(eventId, tokenId, owner.address);
        const tokenDetails = await eventFactoryFacet.tokenDetails(eventId, tokenId);

        expect(userTokens).to.equal(0);
        expect(tokenDetails.currentTotal).to.equal(0);
    });
});

    // Continue with other tests for submitTokens, reimburseUser, cancelEvent, and withdrawTokens...

