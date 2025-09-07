// File: interfaces/IStakeConfig.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/// @title IStakeConfig
/// @notice This interface defines the functions for retrieving staking configuration.
///         It includes functions for both StakingContract logic and UI display.
interface IStakeConfig {
    /// @notice Returns the calculated earning rate for a user based on their level and stake type.
    /// @param _user The address of the user.
    /// @param _pairedToken The address of the paired token for double stake (address(0) for single stake).
    /// @return The total earning rate in basis points (0 if user cannot earn due to level).
    function getStakeRate(address _user, address _pairedToken) external view returns (uint16);

    /// @notice Checks if a user is eligible to stake based on their membership level.
    /// @param _user The address of the user.
    /// @return True if the user meets the minimum membership level to stake, false otherwise.
    function canStake(address _user) external view returns (bool);

    // --- New Getter functions for UI/display purposes ---

    /// @notice Retrieves the raw single stake rate for a specific membership level.
    /// @param _level The membership level to query.
    /// @return The single stake rate in basis points.
    function getSingleStakeRateForLevel(int64 _level) external view returns (uint16);

    /// @notice Retrieves the raw additional double stake rate for a specific paired token and level.
    /// @param _pairedToken The address of the paired token.
    /// @param _level The membership level to query.
    /// @return The additional double stake rate in basis points.
    function getAdditionalDoubleStakeRateForLevel(address _pairedToken, int64 _level) external view returns (uint16);

    /// @notice Retrieves the total combined rate for a specific paired token and level, useful for UI display.
    /// @param _pairedToken The address of the paired token (address(0) for single stake).
    /// @param _level The membership level to query.
    /// @return The total combined stake rate in basis points.
    function getTotalRateForLevel(address _pairedToken, int64 _level) external view returns (uint16);

    /// @notice Returns the minimum membership level required to stake.
    function getMinStakeLevel() external view returns (int64);
}