// LibEventStorage.sol
pragma solidity ^0.8.0;

import "../interfaces/IERC1155Transfer.sol";

library LibEventFactoryStorage {
    bytes32 constant STORAGE_POSITION = keccak256("diamond.storage.EventFactory");

    struct TicketDetail {
        uint256 minAmount;
        uint256 maxAmount;
    }

    enum EventStatus {
        Pending,
        Active,
        Deactivated,
        Completed
    }

    struct EventDetail {
        uint32 startTime;
        uint32 endTime;
        uint256 minEntries;
        uint256 maxEntries;
        uint256 currentEntries;
        string imageUri;
        EventStatus status;
        bytes32 merkleRoot;
        mapping(uint256 => TicketDetail) ticketDetails;
        mapping(address => mapping(uint256 => uint256)) ticketsRedeemed;
    }

    struct EventStorage {
        address owner;
        IERC1155Transfer tokenContract;
        mapping(uint256 => EventDetail) events;
    }

    function eventStorage() internal pure returns (EventStorage storage es) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            es.slot := position
        }
    }

    function getEventDetail(uint256 eventId) internal view returns (EventDetail storage) {
        EventStorage storage es = eventStorage();
        require(es.events[eventId].startTime != 0, "Event does not exist");
        return es.events[eventId];
    }

    function getTicketDetail(uint256 eventId, uint256 ticketId) internal view returns (TicketDetail storage) {
        return getEventDetail(eventId).ticketDetails[ticketId];
    }

    function getRedeemedTickets(uint256 eventId, address user, uint256[] memory ticketId) internal view returns (uint256[] memory) {
        uint256[] memory redeemedTickets = new uint256[](ticketId.length);
        for (uint256 i; i < ticketId.length; i++) {
            redeemedTickets[i] = getEventDetail(eventId).ticketsRedeemed[user][ticketId[i]];
        }
        return redeemedTickets;
    }

    function getMerkleRoot(uint256 eventId) internal view returns (bytes32) {
        return getEventDetail(eventId).merkleRoot;
    }

    function getEventTimes(uint256 eventId) internal view returns (uint32 startTime, uint32 endTime) {
        EventDetail storage es = getEventDetail(eventId);
        return (es.startTime, es.endTime);
    }

    function getEventEntries(uint256 eventId) internal view returns (uint256 minEntries, uint256 maxEntries, uint256 currentEntries) {
        EventDetail storage es = getEventDetail(eventId);
        return (es.minEntries, es.maxEntries, es.currentEntries);
    }

    function getEventImageUri(uint256 eventId) internal view returns (string memory) {
        EventDetail storage es = getEventDetail(eventId);
        return es.imageUri;
    }

    function getEventStatus(uint256 eventId) internal view returns (EventStatus) {
        EventDetail storage es = getEventDetail(eventId);
        return es.status;
    }
}
