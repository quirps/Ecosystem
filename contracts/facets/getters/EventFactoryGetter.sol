// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../libraries/LibEventFactory.sol";
import "../../interfaces/IEventFactoryGetter.sol";

contract EventFactoryGettersFacet is IEventGetterFacet {


    function getEventDetails(uint256 eventId) external view override returns (
        uint32 startTime,
        uint32 endTime,
        uint256 minEntries,
        uint256 maxEntries,
        uint256 currentEntries,
        string memory imageUri,
        uint8 status
    ) {
        LibEventFactoryStorage.EventDetail storage eventDetail = LibEventFactoryStorage.getEventDetail(eventId);

        startTime = eventDetail.startTime;
        endTime = eventDetail.endTime;
        minEntries = eventDetail.minEntries;
        maxEntries = eventDetail.maxEntries;
        currentEntries = eventDetail.currentEntries;
        imageUri = eventDetail.imageUri;
        status = uint8(eventDetail.status);
    }

    function getEventTimes(uint256 eventId) external view override returns (uint32 startTime, uint32 endTime) {
        (startTime, endTime) = LibEventFactoryStorage.getEventTimes(eventId);
    }

    function getEventEntries(uint256 eventId) external view override returns (uint256 minEntries, uint256 maxEntries, uint256 currentEntries) {
        (minEntries, maxEntries, currentEntries) = LibEventFactoryStorage.getEventEntries(eventId);
    }

    function getEventImageUri(uint256 eventId) external view override returns (string memory) {
        return LibEventFactoryStorage.getEventImageUri(eventId);
    }

    function getEventStatus(uint256 eventId) external view override returns (uint8) {
        return uint8(LibEventFactoryStorage.getEventStatus(eventId));
    }
}
