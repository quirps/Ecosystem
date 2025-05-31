// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19; // Use a consistent recent version

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IEventFacet } from "../facets/Events/IEventFactory.sol"; // Adjust path if needed
import { LibEventFactory } from "../facets/Events/LibEventFactory.sol"; // Adjust path if needed
 
/**
 * @title RedemptionApp
 * @notice Handles the burning of specific tokens for off-chain fulfillment,
 * associated with an event configured on the EventFacet.
 * @dev Meant to be deployed per ecosystem. Calls back to the parent EventFacet
 * for core checks and token burning. Users must approve this contract
 * to spend their redeemable tickets.
 */
contract RedemptionApp is Ownable {

    // --- State Variables ---

    // Address of the parent Ecosystem Diamond's EventFacet interface
    address public immutable EVENT_FACET_ADDRESS;

    // Optional state for tracking (can rely on EventFacet's maxEntriesPerUser)
    mapping(uint256 => mapping(address => bool)) public hasRedeemed;

    // --- Events ---

    /**
     * @dev Emitted when a user successfully burns a token via this app.
     * @param eventId The associated event ID from the EventFacet.
     * @param user The user who redeemed the token.
     * @param ticketId The ID of the token redeemed.
     * @param amount The amount redeemed.
     * @param data Optional data passed by the user during redemption.
     */
    event Redeemed(
        uint256 indexed eventId,
        address indexed user,
        uint256 indexed ticketId,
        uint256 amount,
        bytes data // Keep data field for potential off-chain use
    );

    // --- Errors ---
    error AlreadyRedeemed(uint256 eventId, address user);
    error CoreParticipationFailed(uint256 eventId, address user);
    error ZeroAddress();

    // --- Constructor ---

    /**
     * @param _eventFacetAddress The address of the parent Ecosystem Diamond proxy.
     */
    constructor(address _eventFacetAddress) Ownable(msg.sender) {
        if (_eventFacetAddress == address(0)) revert ZeroAddress();
        EVENT_FACET_ADDRESS = _eventFacetAddress;
    }

    // --- User-Facing Function ---

    /**
     * @notice Allows a user to redeem (burn) a specific ticket associated with an event.
     * @dev User calls this directly on this RedemptionApp instance. Verifies core rules
     * and burns the token via the parent EventFacet, then emits a Redeemed event.
     * @param eventId The ID of the redemption event config on the EventFacet.
     * @param ticketId The ID of the ERC1155 ticket to be redeemed.
     * @param amount The amount of the ticket required (must match event config on Facet).
     * @param data Optional arbitrary data from the user (e.g., details for fulfillment).
     */
    function redeem(uint256 eventId, uint256 ticketId, uint256 amount, bytes calldata data) external {
        // 1. Define expected interaction (Must be Burn for redemption)
        LibEventFactory.TicketInteraction expectedInteraction = LibEventFactory.TicketInteraction.Burn;

        // 2. Verify core participation via EventFacet
        // Note: User (msg.sender) must have approved THIS RedemptionApp contract address
        //       for the specified ticketId and amount on the parent Diamond's ERC1155.
        IEventFacet eventFacet = IEventFacet(EVENT_FACET_ADDRESS);
        bool success = eventFacet.verifyAndProcessParticipation(
            eventId,
            msg.sender, // The user redeeming
            ticketId,
            amount
        );

        // 3. Check Facet Verification Result
        if (!success) revert CoreParticipationFailed(eventId, msg.sender);

        // 4. Local Redemption Validations (Optional - check if already redeemed)
        // This relies on EventFacet's maxEntriesPerUser primarily, but local check adds defense.
        if (hasRedeemed[eventId][msg.sender]) revert AlreadyRedeemed(eventId, msg.sender);

        // 5. Record Redemption Locally (Optional - mark as redeemed)
        hasRedeemed[eventId][msg.sender] = true;

        // 6. Emit the critical Redeemed event for off-chain monitoring
        emit Redeemed(eventId, msg.sender, ticketId, amount, data);
    }

    // --- Getter Functions (Optional) ---

    function getHasRedeemed(uint256 eventId, address user) external view returns (bool) {
        return hasRedeemed[eventId][user];
    }

    // No setter for EVENT_FACET_ADDRESS as it's immutable
}