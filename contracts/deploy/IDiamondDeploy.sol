// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title DiamondDeploy Interface
/// @notice Interface for the DiamondDeploy contract
/// @dev This interface describes the methods available in the DiamondDeploy contract
interface IDiamondDeploy {


    /// @notice Deploy a new Diamond contract
    /// @dev Deploys a new Diamond contract and returns its address
    /// @param _bytecode The bytecode of the contract to deploy
    /// @return diamond_ The address of the newly deployed Diamond
    function deploy(bytes memory _bytecode) external returns (address diamond_);

    /// @notice Get the address of the DiamondCutFacet
    /// @dev Returns the address of the DiamondCutFacet associated with this DiamondDeploy contract
    /// @return The address of the DiamondCutFacet
    function diamondCutFacet() external view returns (address);
}
