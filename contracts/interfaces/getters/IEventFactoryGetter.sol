// @title IEventGetterFacet
/// @dev Interface for the event getters facet
interface IEventGetter {

    /// @notice Retrieves the details of an event
    /// @dev External view function to get all details of an event
    /// @param eventId The ID of the event
    /// @return startTime The start time of the event
    /// @return endTime The end time of the event
    /// @return minEntries The minimum number of entries for the event
    /// @return maxEntries The maximum number of entries for the event
    /// @return currentEntries The current number of entries for the event
    /// @return imageUri The image URI for the event
    /// @return status The status of the event
    function getEventDetails(uint256 eventId) external view returns (
        uint32 startTime,
        uint32 endTime,
        uint256 minEntries,
        uint256 maxEntries,
        uint256 currentEntries,
        string memory imageUri,
        uint8 status
    );

    /// @notice Retrieves the start and end times of an event
    /// @param eventId The ID of the event
    /// @return startTime The start time of the event
    /// @return endTime The end time of the event
    function getEventTimes(uint256 eventId) external view returns (uint32 startTime, uint32 endTime);

    /// @notice Retrieves the entry details of an event
    /// @param eventId The ID of the event
    /// @return minEntries The minimum number of entries for the event
    /// @return maxEntries The maximum number of entries for the event
    /// @return currentEntries The current number of entries for the event
    function getEventEntries(uint256 eventId) external view returns (uint256 minEntries, uint256 maxEntries, uint256 currentEntries);

    /// @notice Retrieves the image URI of an event
    /// @param eventId The ID of the event
    /// @return The image URI for the event
    function getEventImageUri(uint256 eventId) external view returns (string memory);

    /// @notice Retrieves the status of an event
    /// @param eventId The ID of the event
    /// @return The status of the event
    function getEventStatus(uint256 eventId) external view returns (uint8);
}
