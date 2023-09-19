const {
  expect
} = require("chai");
const {
  ethers
} = require('hardhat')
const {
  main
} = require("../deploy/main")

const config = {
  ticketDistributions: [
    { address: 'addr1', ticketId: 1, amount: 10 },
    { address: 'addr2', ticketId: 1, amount: 5 },
    { address: 'addr1', ticketId: 2, amount: 20 },
    { address: 'addr2', ticketId: 2, amount: 15 },
  ],
};
const EventStatus = new Map([
  ['Pending', 0],
  ['Active', 1],
  ['Deactivated', 2],
  ['Expired', 3]
])
describe("EventFactory", function () {
  let ecosystem;
  let owner;
  let addr1;
  let addr2;
  
  before(async function () {
    [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
    setConfigAddresses([addr1,addr2])
    ecosystem = await main("", false)
    // fundUsers, approve contract
    console.log(3)
  });

  describe("createEvent", function () {
    const minEntries = 1;
    let maxEntries = 100;
    const imageUri = "https://example.com/image.png";
    const ticketIds = [1, 2];
    const ticketDetails = [
      [50, 100],
      [100, 200]
    ];
    it("Should create an event with 'Pending' status given the start time is in the future", async function () {
      // Get the current block timestamp and set start and end times in the future
      const blockTimestamp = (await ethers.provider.getBlock('latest')).timestamp;
      const startTime = blockTimestamp + 1000;
      const endTime = blockTimestamp + 2000;



      // Create the event
      const tx = await ecosystem.createEvent(
        startTime, endTime, minEntries, maxEntries, imageUri, ticketIds, ticketDetails
      );

      // Get the event details from the emitted event
      const receipt = await tx.wait();
      const eventId = receipt.events[0].args.eventId;

      // Fetch the event details from the contract and verify them
      const event = await ecosystem.getEventDetails(eventId);
      expect(event.startTime).to.equal(startTime);
      expect(event.endTime).to.equal(endTime);
      expect(event.status).to.equal(EventStatus.get("Pending"));
    });

    it("Should create an event with 'Active' status given the start time is now or in the past", async function () {
      // The same steps as the previous test, but with startTime <= blockTimestamp
      const blockTimestamp = (await ethers.provider.getBlock('latest')).timestamp;
      const startTime = blockTimestamp - 100;
      const endTime = blockTimestamp + 1000;
      // ... (use the same parameters as the previous test, and the same steps to create the event and verify the result)


      const tx = await ecosystem.createEvent(
        startTime, endTime, minEntries, maxEntries, imageUri, ticketIds, ticketDetails
      );

      const receipt = await tx.wait();
      const eventId = receipt.events[0].args.eventId;

      const event = await ecosystem.getEventDetails(eventId);
      expect(event.status).to.equal(EventStatus.get("Active"));
    });

    // Similar tests for verifying the EventDetails and TicketDetails events are emitted correctly
    it("Should emit EventDetails event with correct details", async function () {
      // ... (similar to previous tests: set up parameters, create event, get receipt)
      const blockTimestamp = (await ethers.provider.getBlock('latest')).timestamp;
      const startTime = blockTimestamp + 1000;
      const endTime = blockTimestamp + 2000;



      const tx = await ecosystem.createEvent(
        startTime, endTime, minEntries, maxEntries, imageUri, ticketIds, ticketDetails
      );

      const receipt = await tx.wait();
      const eventDetailsEvent = receipt.events.find(event => event.event === "EventDetails");

      expect(eventDetailsEvent.args.startTime).to.equal(startTime);
      expect(eventDetailsEvent.args.endTime).to.equal(endTime);
      // ... (verify other event parameters)
    });

    it("Should emit TicketDetails event with correct details", async function () {
      // ... (similar to previous tests: set up parameters, create event, get receipt)
      const blockTimestamp = (await ethers.provider.getBlock('latest')).timestamp;
      const startTime = blockTimestamp + 1000;
      const endTime = blockTimestamp + 2000;



      const tx = await ecosystem.createEvent(
        startTime, endTime, minEntries, maxEntries, imageUri, ticketIds, ticketDetails
      );

      const receipt = await tx.wait();
      const ticketDetailsEvent = receipt.events.find(event => event.event === "TicketDetails");

      expect(ticketDetailsEvent.args.ticketIds).to.deep.equal(ticketIds);
      // ... (verify other event parameters, potentially needing to parse the structs to do so)
    });
    it("Should create unique event IDs for events created at different times", async function () {
      const blockTimestamp = (await ethers.provider.getBlock('latest')).timestamp;
      const startTime = blockTimestamp + 1000;
      const endTime = blockTimestamp + 2000;

      // Create the first event
      const tx1 = await ecosystem.createEvent(
        startTime, endTime, minEntries, maxEntries, imageUri, ticketIds, ticketDetails
      );
      const receipt1 = await tx1.wait();
      const eventId1 = receipt1.events[0].args.eventId;

      // Wait for some time to ensure a different block timestamp
      await new Promise(resolve => setTimeout(resolve, 1000));

      // Create the second event
      const tx2 = await ecosystem.createEvent(
        startTime, endTime, minEntries, maxEntries, imageUri, ticketIds, ticketDetails
      );
      const receipt2 = await tx2.wait();
      const eventId2 = receipt2.events[0].args.eventId;

      // The event IDs should be different
      expect(eventId1).to.not.equal(eventId2);
    });

    it("Should fail to create an event with end time in the past", async function () {
      const blockTimestamp = (await ethers.provider.getBlock('latest')).timestamp;
      const startTime = blockTimestamp - 2000;
      const endTime = blockTimestamp - 1000;

      await expect(
        ecosystem.createEvent(
          startTime, endTime, minEntries, maxEntries, imageUri, ticketIds, ticketDetails
        )
      ).to.be.revertedWith("Must be non-trivial event time window");
    });

    it("Should fail to create an event with mismatched ticket IDs and details arrays", async function () {
      const blockTimestamp = (await ethers.provider.getBlock('latest')).timestamp;
      const startTime = blockTimestamp + 1000;
      const endTime = blockTimestamp + 2000;

      const invalidTicketDetails = [
        [50, 100]
      ];

      await expect(
        ecosystem.createEvent(
          startTime, endTime, minEntries, maxEntries, imageUri, ticketIds, invalidTicketDetails
        )
      ).to.be.revertedWith("Must be same length.");
    });

    it("Should fail to create an event with a ticket having zero max amount", async function () {
      const blockTimestamp = (await ethers.provider.getBlock('latest')).timestamp;
      const startTime = blockTimestamp + 1000;
      const endTime = blockTimestamp + 2000;
      let maxEntries = 0;
      const invalidTicketDetails = [
        [0, 100],
        [100, 200]
      ];

      await expect(
        ecosystem.createEvent(
          startTime, endTime, minEntries, maxEntries, imageUri, ticketIds, invalidTicketDetails
        )
      ).to.be.revertedWith("Must have non-trivial entrant amount");
    });
  });


  //==============================================================================================================
  
  describe("_redeemTickets", function () {
    let ecosystem;
    let owner;
    let addr1;
    let addr2;
    let eventId;
    
    before(async function () {
      [owner, addr1, addr2, ...addrs] = await ethers.getSigners();
      ecosystem = await main("", false);
  
      // Mint tickets as per the config and approve the contract for ERC1155
      for (const dist of config.ticketDistributions) {
        await ecosystem.mintTickets(dist.address, dist.ticketId, dist.amount);
        await ecosystem.approveERC1155(ecosystem.address, dist.ticketId, dist.amount);
      }
  
      // 1. Create an event with a future start and end time
      const blockTimestamp = (await ethers.provider.getBlock('latest')).timestamp;
      const startTime = blockTimestamp + 1000;
      const endTime = blockTimestamp + 2000;
      const minEntries = 1;
      const maxEntries = 100;
      const imageUri = "https://example.com/image.png";
      const ticketIds = [1, 2];
      const ticketDetails = [[50, 100], [100, 200]];
      
      const tx = await ecosystem.createEvent(startTime, endTime, minEntries, maxEntries, imageUri, ticketIds, ticketDetails);
      const receipt = await tx.wait();
      eventId = receipt.events[0].args.eventId;
    });
  
    it("Should successfully redeem tickets when the event is active", async function () {
      // 2. Change the blockchain time to make the event active
      const blockTimestamp = (await ethers.provider.getBlock('latest')).timestamp;
      await ethers.provider.send('evm_increaseTime', [1000]);
      await ethers.provider.send('evm_mine'); // This will mine a new block and therefore increase the block's timestamp
  
      // 3. Call the _redeemTickets function with valid inputs
      const ticketIds = [1, 2];
      const amounts = [1, 1];
      const tx = await ecosystem.connect(addr1)._redeemTickets(eventId, ticketIds, amounts);
  
      // 4. Verify that the correct events are emitted
      const receipt = await tx.wait();
      const ticketRedeemedEvent = receipt.events.find(event => event.event === "TicketRedeemed");
      expect(ticketRedeemedEvent.args.ticketIds).to.deep.equal(ticketIds);
      expect(ticketRedeemedEvent.args.amounts).to.deep.equal(amounts);
  
      // 5. Verify that the event and ticket details have been updated correctly in the contract's storage
      const eventDetails = await ecosystem.getEventDetails(eventId);
      expect(eventDetails.currentEntries).to.equal(2); // 2 tickets were redeemed
      for (let i = 0; i < ticketIds.length; i++) {
        const ticketsRedeemed = await ecosystem.getTicketsRedeemed(eventId, addr1.address, ticketIds[i]);
        expect(ticketsRedeemed).to.equal(amounts[i]);
      }
    });
  });

});