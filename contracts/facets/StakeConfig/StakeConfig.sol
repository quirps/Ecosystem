// File: external/StakeConfigFacet.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "../Ownership/_Ownership.sol";
import "./IStakeConfig.sol";
import "./LibStakeConfig.sol";
import "../MemberLevel/_MembershipLevels.sol";
/// @title StakeConfigFacet
/// @notice This is a mock Diamond facet implementation for managing staking configuration.
///         It includes convenient setter and getter functions for the ecosystem owner.
contract StakeConfig is IStakeConfig, iOwnership, iMembers{
    // --- Internal Logic ---



    // --- Core StakingContract Functions (from IStakeConfig) ---

    /// @inheritdoc IStakeConfig
    function getStakeRate(address _user, address _pairedToken) external view returns (uint16) {
        LibStakeConfigStorage.StakeConfigStorage storage s = LibStakeConfigStorage.stakeConfigStorage();
        int64 userLevel = _getMemberLevel(_user);
        uint16 totalRate = s.singleStakeRates[userLevel];

        if (_pairedToken != address(0)) {
            totalRate += s.additionalDoubleStakeRates[_pairedToken][userLevel];
        }

        if (userLevel < s.minStakeLevel) {
            return 0;
        }

        return totalRate;
    }

    /// @inheritdoc IStakeConfig
    function canStake(address _user) external view returns (bool) {
        LibStakeConfigStorage.StakeConfigStorage storage s = LibStakeConfigStorage.stakeConfigStorage();

        int64 userLevel = _getMemberLevel(_user);
        return userLevel >= s.minStakeLevel;
    }

    // --- New Getter Functions for UI/Display ---

    /// @inheritdoc IStakeConfig
    function getSingleStakeRateForLevel(int64 _level) external view returns (uint16) {
        LibStakeConfigStorage.StakeConfigStorage storage s = LibStakeConfigStorage.stakeConfigStorage();

        return s.singleStakeRates[_level];
    }

    /// @inheritdoc IStakeConfig
    function getAdditionalDoubleStakeRateForLevel(address _pairedToken, int64 _level) external view returns (uint16) {
        LibStakeConfigStorage.StakeConfigStorage storage s = LibStakeConfigStorage.stakeConfigStorage();

        return s.additionalDoubleStakeRates[_pairedToken][_level];
    }

    /// @inheritdoc IStakeConfig
    function getTotalRateForLevel(address _pairedToken, int64 _level) external view returns (uint16) {
        LibStakeConfigStorage.StakeConfigStorage storage s = LibStakeConfigStorage.stakeConfigStorage();

        uint16 totalRate = s.singleStakeRates[_level];
        if (_pairedToken != address(0)) {
            totalRate += s.additionalDoubleStakeRates[_pairedToken][_level];
        }
        return totalRate;
    }

    /// @inheritdoc IStakeConfig
    function getMinStakeLevel() external view returns (int64) {
        LibStakeConfigStorage.StakeConfigStorage storage s = LibStakeConfigStorage.stakeConfigStorage();

        return s.minStakeLevel;
    }

    // --- Convenient Setter Functions (Owner-Only) ---

    /// @notice Sets the single stake rates for a batch of membership levels.
    /// @dev This can be used by an owner to easily update a whole tier structure.
    ///      Restricted to the Diamond owner.
    /// @param _levels An array of membership levels.
    /// @param _rates An array of corresponding single stake rates in basis points.
    function setSingleStakeRates(int64[] calldata _levels, uint16[] calldata _rates) external onlyOwner {
        LibStakeConfigStorage.StakeConfigStorage storage s = LibStakeConfigStorage.stakeConfigStorage();

        require(_levels.length == _rates.length, "StakeConfig: Levels and rates arrays must have same length");
        for (uint256 i = 0; i < _levels.length; i++) {
            require(_levels[i] >= 0, "StakeConfig: Level must be non-negative");
            s.singleStakeRates[_levels[i]] = _rates[i];
        }
    }

    /// @notice Sets the additional double stake rates for a batch of membership levels and a specific paired token.
    /// @dev Restricted to the Diamond owner.
    /// @param _pairedToken The address of the paired token.
    /// @param _levels An array of membership levels.
    /// @param _rates An array of corresponding additional double stake rates in basis points.
    function setAdditionalDoubleStakeRates(address _pairedToken, int64[] calldata _levels, uint16[] calldata _rates) external onlyOwner {
        LibStakeConfigStorage.StakeConfigStorage storage s = LibStakeConfigStorage.stakeConfigStorage();

        require(_pairedToken != address(0), "StakeConfig: Paired token cannot be zero");
        require(_levels.length == _rates.length, "StakeConfig: Levels and rates arrays must have same length");
        for (uint256 i = 0; i < _levels.length; i++) {
            require(_levels[i] >= 0, "StakeConfig: Level must be non-negative");
            s.additionalDoubleStakeRates[_pairedToken][_levels[i]] = _rates[i];
        }
    }

    /// @notice Sets the minimum membership level required to stake.
    /// @dev Restricted to the Diamond owner.
    function setMinStakeLevel(int64 _level) external onlyOwner {
        LibStakeConfigStorage.StakeConfigStorage storage s = LibStakeConfigStorage.stakeConfigStorage();
        require(_level >= 0, "StakeConfig: Minimum level must be non-negative");
        s.minStakeLevel = _level;
    }
}
