// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;


/// @title Global and Owner Freezing
/// @author Quirp
/// @notice Two Functionalities - Global Freeze: Freezes Diamond completely, aside from this facet
///                                              Must be manually frozen/unfrozen via owner.  
///                                              Can set lockout time, which owner must wait before unfreezing.
///                                              Can extend lockout time while in frozen state. 
///                               Owner Freeze : Freezes onlyOwner facets
///                                              Explicitly, this means facets with onlyOwner are removed
///                                              
/// @dev Special status must be given to these facets as they:
///      1: Must manage allowed diamond selectors (i.e. Global freeze must remove all selectors aside from its own)
///      2: Must store facet/selector state of those removed due to freeze. This must be done as freezes are done
///         by the user


interface IFreezeOwner{
    event FrozenOwner(address indexed _owner, uint256 indexed duration);
    event UnFrozenOwner(address indexed _owner);

function init(uint256 _amount, address _test, address _receiver, address _tokenLeadContract) external;

    /// @notice Instantiates a global freeze of the diamond. More precisely, 
    ///         all of the diamond's current facet/selectors are cached and 
    ///         delete from router's access aside from this contract's selectors
    /// 
    /// @param _freezeDuration Duration from block.timestamp this facet will be
    ///                        in a globally frozen state
    function freezeOwner(uint256 _freezeDuration) external;
    
    /// @notice Unfreezes a global freeze state IF called by the owner and
    ///         freeze duration has expired. Restores the facet/selector mapping
    ///         that was cached immedietely prior to freeze
    function unFreezeOwner() external;

    /// @notice Extends the global freeze duration.
    /// 
    /// @param _freezeDuration Extends the current freeze duration by this amount
    function extendFreezeOwner(uint256 _freezeDuration)external;

    /// @notice Gets freeze expiration timestamp
    /// 
    /// @return uint256 freeze expiration timestamp
    function freezeExpireOwner() external returns (uint256) ;

    /// @notice Gets current freeze state
    /// 
    /// @return bool true if in frozen state
    function isFrozenGlobal() external returns(bool);

   function getFreezeOwner() external returns(address);
   

}