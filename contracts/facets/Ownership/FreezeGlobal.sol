// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;


import "./LibFreeze.sol";
import "./IFreezeGlobal.sol";
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

/// Freeze Facet 
/// onlyOwner must be added to freeze init module
/// Once freeze OWNER is added, Constructor takes in (address,signature) pairs that consist of onlyOwner modifiers
/// Easier fix to OWNER is just set owner to zero address, then after time enable _owner (old owner) to reclaim ownership
contract FreezeGlobal is IFreezeGlobal()  {

    address public immutable facetAddress;
    constructor(){
        facetAddress = address(this);
    }
    function init(bytes4[] calldata _selectors)external override {
        LibFreeze.FreezeStorage storage fs = LibFreeze.freezeStorage();
        fs.globalFreezeSelectors = _selectors;

    }
    /// @notice Instantiates a global freeze of the diamond. More precisely, 
    ///         all of the diamond's current facet/selectors are cached and 
    ///         delete from router's access aside from this contract's selectors
    /// 
    /// @param _freezeDuration Duration from block.timestamp this facet will be
    ///                        in a globally frozen state

    function freezeGlobal(uint256 _freezeDuration) external override {
        LibFreeze.freezeGlobal(_freezeDuration,facetAddress);
    }
    function unFreezeGlobal() external override{
        LibFreeze.unFreezeGlobal(facetAddress);
    }
    function extendFreezeGlobal(uint256 _freezeDuration) external override{
        LibFreeze.extendFreezeGlobal( _freezeDuration );
    }
    function freezeExpireGlobal() external override view returns (uint256 freezeExpire_){
        LibFreeze.FreezeStorage storage fs = LibFreeze.freezeStorage();
        freezeExpire_ = fs.frozenGlobalExpire;
    }
    function isFrozenGlobal() external override view returns (bool isFrozenGlobal_){
        LibFreeze.FreezeStorage storage fs = LibFreeze.freezeStorage();
        isFrozenGlobal_ = fs.frozenGlobalExpire < block.timestamp; 
    }
  
    function freezeCachedSelectors() external override view returns (bytes4[] memory cachedSelectors_){
        LibFreeze.FreezeStorage storage fs = LibFreeze.freezeStorage();
        cachedSelectors_ = fs.freezeCachedSelectors; 
    }
    
    function freezeGlobalSelectors() external override view returns (bytes4[] memory globalFreezeSelectors_){
        LibFreeze.FreezeStorage storage fs = LibFreeze.freezeStorage();
        globalFreezeSelectors_ = fs.globalFreezeSelectors; 
    }
}