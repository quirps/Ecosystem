pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

import "../libraries/LibFreeze.sol";
import "../internals/iFreezeOwner.sol";
/// @title Owner Freezing
/// @author Quirp
/// @notice Freezes (removes) the owner for an extended duration.
///                                              
/// @dev changes owner state variable to the zero address for the 
///      given freeze duration at minimum


contract iFreezeOwner {
    event FrozenOwner(address indexed _owner, uint256 indexed duration);
    event UnFrozenOwner(address indexed _owner);

}
