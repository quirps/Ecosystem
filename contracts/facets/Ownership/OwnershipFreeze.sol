// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

import "../../libraries/LibFreeze.sol";
import "../../internals/iFreezeOwner.sol";
/// @title Owner Freezing
/// @author Quirp
/// @notice Freezes (removes) the owner for an extended duration.
///                                              
/// @dev changes owner state variable to the zero address for the 
///      given freeze duration at minimum


contract OwnershipFreeze is iFreezeOwner  {
    // event Init(uint256 indexed _a, address indexed _b, address _c);
    // function init(uint256 _amount, address _test, address _receiver, address _tokenLeadContract) external {
    //     LibFreeze.FreezeStorage storage fs = LibFreeze.freezeStorage();
    //     fs.test  = _test;
    //     emit Init(_amount, _test, _receiver);
    // }

    /// @notice Freezes (removes) the owner for an extended duration.
    /// 
    /// @param _freezeDuration Duration from block.timestamp this facet will be
    ///                        in an ownerless state

    function freezeOwner(uint256 _freezeDuration) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        LibFreeze.FreezeStorage storage fs = LibFreeze.freezeStorage();
        address _contractOwner = ds.contractOwner;

        LibFreeze.isContractOwner(_contractOwner);
        
        address _frozenOwner = fs.frozenOwner;

        uint256 _expireTimestamp = block.timestamp + _freezeDuration;
        fs.frozenOwnerExpire = _expireTimestamp;
        emit FrozenOwner(_contractOwner, _expireTimestamp);
        fs.frozenOwner = _contractOwner;
        ds.contractOwner = address(0);
    }
    function unFreezeOwner() external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        LibFreeze.FreezeStorage storage fs = LibFreeze.freezeStorage();
        address _frozenOwner = fs.frozenOwner;
        LibFreeze.enforceFrozenOwner(_frozenOwner);
        LibFreeze.enforeFreezeDurationExpire();

        ds.contractOwner = _frozenOwner;
        fs.frozenOwner = address(0);

        emit UnFrozenOwner(_frozenOwner);
    }
    function extendFreezeOwner(uint256 _freezeDuration) external {
        LibFreeze.FreezeStorage storage fs = LibFreeze.freezeStorage();
        address _frozenOwner = fs.frozenOwner;
        LibFreeze.enforceFrozenOwner(_frozenOwner);
        LibFreeze.enforeFreezeDurationExpire();

        uint256 _expireTimestamp = fs.frozenOwnerExpire + _freezeDuration;

        fs.frozenOwnerExpire = _expireTimestamp;
        emit FrozenOwner(_frozenOwner, _expireTimestamp);

    }
    function freezeExpireOwner() external view returns (uint256 freezeExpire_){
        LibFreeze.FreezeStorage storage fs = LibFreeze.freezeStorage();
        freezeExpire_ = fs.frozenOwnerExpire;
    }
    function isFrozenOwner() external view returns (bool isFrozenGlobal_){
        LibFreeze.FreezeStorage storage fs = LibFreeze.freezeStorage();
        isFrozenGlobal_ = fs.frozenOwner != address(0); 
    }
    function getFreezeOwner() external returns (address owner_){
        LibFreeze.FreezeStorage storage fs = LibFreeze.freezeStorage();
        owner_ = fs.frozenOwner;
    }
    
}
    

