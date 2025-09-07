// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "../facets/StakeConfig/IStakeConfig.sol"; // Import the StakeConfig interface

library LibStake {
    enum StakingType {
        Single,
        Double
    }

    // Struct to hold a user's staking position details
    struct StakePosition {
        uint256 amount;          // Amount of tokens staked (for single stake) or liquidity units (for double stake)
        uint256 rewardDebt;      // Amount of rewards already claimed or accounted for
        uint32 lastUpdateTime;   // Last timestamp when rewards were calculated/updated for this position
        StakingType stakeType;   // Type of staking (Single or Double)
        uint256 tokenId;         // Uniswap V3 NFT tokenId for double staking, or a special ID for single staking.
    }

    /// @notice Calculates pending rewards for a user's position.
    /// @param _stakeConfig The IStakeConfig interface instance for the current ecosystem.
    /// @param _position The staking position struct.
    /// @param _user The user's address (passed to getStakeRate).
    /// @param _pairedToken For double stake, the address of the token paired with ecosystemToken.
    ///                     address(0) for single stake.
    /// @return pendingRewards amount of pending rewards for the user.
    function _calculatePendingRewards(
        IStakeConfig _stakeConfig, // Passed directly now
        StakePosition storage _position,
        address _user,             // User address needed for getStakeRate
        address _pairedToken       // Paired token needed for getStakeRate
    ) internal view returns (uint256 pendingRewards) {
        if (_position.amount == 0) {
            return 0; // No staked amount, no rewards
        }

        uint32 timeElapsed = uint32(block.timestamp) - _position.lastUpdateTime;
        if (timeElapsed == 0) {
            return 0; // No time elapsed, no new rewards
        }

        // Get the rate directly from StakeConfigFacet, which handles member level internally
        uint16 currentRate = _stakeConfig.getStakeRate(_user, _pairedToken);

        uint256 BASIS_POINTS_DENOMINATOR = 10000;
        uint256 SECONDS_IN_YEAR = 31536000; // 365 * 24 * 60 * 60

        // Rewards = (stakedAmount * rate * timeElapsed) / (BASIS_POINTS_DENOMINATOR * SECONDS_IN_YEAR)
        pendingRewards = (_position.amount * currentRate * timeElapsed) / (BASIS_POINTS_DENOMINATOR * SECONDS_IN_YEAR);

        return pendingRewards;
    }

    /// @notice Updates a user's staking position's lastUpdateTime.
    function _updatePositionTimestamp(StakePosition storage _position) internal {
        _position.lastUpdateTime = uint32(block.timestamp);
    }

    /// @notice Generates a unique tokenId for single staking to differentiate it in storage.
    /// This ID is unique per ecosystem.
    function _getSingleStakeIdentifier() internal pure returns (uint256) {
        // Using max uint256 as a distinct ID for single stake, unlikely to conflict with NFT tokenIds.
        return type(uint256).max;
    }
}