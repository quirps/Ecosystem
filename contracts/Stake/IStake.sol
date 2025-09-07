// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

// This interface defines how the StakingContract will query configuration
// from the external "Ecosystem Configuration" contract.
interface IEcosystemConfig {
    function getEcosystemToken() external view returns (address);
    function getUniswapPositionManager() external view returns (address);
    function getMembershipLevelsContract() external view returns (address);

    function getSingleStakeRate(int64 level) external view returns (uint16);
    function getAdditionalDoubleStakeRate(address pairedToken, int64 level) external view returns (uint16);
}