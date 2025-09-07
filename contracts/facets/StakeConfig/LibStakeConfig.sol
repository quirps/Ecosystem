// File: libraries/LibStakeConfigStorage.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/// @title LibStakeConfigStorage
/// @notice A library for managing the shared storage specific to the StakeConfigFacet.
library LibStakeConfigStorage {
    bytes32 constant STAKE_CONFIG_STORAGE_POSITION = keccak256("stake.config.storage");

    struct StakeConfigStorage {
        // Mapping for single stake rates: memberLevel => rate (in basis points)
        mapping(int64 => uint16) singleStakeRates;
        // Mapping for additional double stake rates: pairedTokenAddress => memberLevel => rate (in basis points)
        mapping(address => mapping(int64 => uint16)) additionalDoubleStakeRates;
        // Minimum membership level required to stake at all in this ecosystem
        int64 minStakeLevel;
    }

    function stakeConfigStorage() internal pure returns (StakeConfigStorage storage s) {
        bytes32 position = STAKE_CONFIG_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }
}