// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
pragma experimental ABIEncoderV2;

import "../Diamond/LibDiamond.sol";
import "./LibOwnership.sol";
import {ERC2771Recipient} from  "../../ERC2771Recipient.sol"; 
library LibFreeze { 

    bytes32 constant FREEZE_STORAGE_POSITION = keccak256("diamond.standard.freeze.storage");
    bytes4 constant FREEZE_GLOBAL = 0x49fc7319;
    bytes4 constant UNFREEZE_GLOBAL = 0x65a34d41;
    bytes4 constant EXTEND_FREEZE_GLOBAL = 0x49fc7319;
    bytes4 constant FREEZE_DURATION_GLOBAL = 0x49fc7319;
    bytes4 constant FREEZE_GLOBAL_SELECTORS = 0x49fc7319;
  
    struct FreezeStorage {
        //FreezeGlobal
        mapping(bytes4 => address) facetFreezeAddress;
        bytes4[] freezeCachedSelectors;

        uint256 frozenGlobalExpire;

        //FrozenOwner
        address frozenOwner;
        uint256 frozenOwnerExpire;
        bytes4[] globalFreezeSelectors;
    }

    event GlobalFreeze(address indexed owner,  uint256 indexed expirationTimestamp);
    event GlobalUnFreeze( address indexed owner);

   function freezeStorage() internal pure returns (FreezeStorage storage fs) {
        bytes32 position = FREEZE_STORAGE_POSITION;
        assembly {
            fs.slot := position
        }
    }

    //FreezeOwner
    //==================================

    function freezeDurationOwner() internal view returns (uint256 freezeExpire_){
        freezeExpire_ = freezeStorage().frozenOwnerExpire;
    }
    function enforceFrozenOwner(address _frozenOwner) internal pure {
        require(_frozenOwner != address(0),"Owner must be frozen");
    }
    function enforeFreezeDurationExpire() internal view{
        FreezeStorage storage fs = freezeStorage();
        require(block.timestamp < fs.frozenOwnerExpire,"Freeze duration must be expired.");
    }
    function isFrozenOwner(address _frozenOwner) internal view  {
        require( msg.sender == _frozenOwner, "Owner isn't currently frozen");
    }

    function frozenOwner() internal view returns (address frozenOwner_) {
        frozenOwner_ = freezeStorage().frozenOwner;
    }

    //Freeze Global
    //============================================
    
    function freezeGlobal(uint256 _freezeDuration, address _facetAddress ) internal  {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        LibOwnership.OwnershipStorage storage os = LibOwnership.ownershipStorage();   

        FreezeStorage storage fs = freezeStorage();
        uint16 _maxFreezeSelectors = 65535; 
        address _owner;
        uint256 _expirationTimestamp;
        address[] memory facetAddresses;
        // bytes4[] memory _freezeCachedSelectors = new bytes4[](_maxFreezeSelectors);
        _owner = os.contractOwner;
        LibOwnership.isContractOwner(_owner);

        facetAddresses = ds.facetAddresses;

        uint16 _arrayIndex;
        for(uint16 i; i < facetAddresses.length; i++){
            if( facetAddresses[i] != _facetAddress ){
                // retrieve selectors of given facet, retrieve address of facet
               bytes4[] memory _facetSelectors = ds.facetFunctionSelectors[ facetAddresses[ i ] ].functionSelectors;
               for ( uint16 ii; ii < _facetSelectors.length; ii++){
                    fs.facetFreezeAddress[ _facetSelectors[ii] ] = facetAddresses[i];
                    // _freezeCachedSelectors[_arrayIndex] = _facetSelectors[ii] ;
                    ds.selectorToFacetAndPosition[ _facetSelectors[ii] ].facetAddress = address(0);
                    _arrayIndex ++;
                } 
            }
        }
        _expirationTimestamp = block.timestamp + _freezeDuration;
        fs.frozenGlobalExpire = _expirationTimestamp;
        emit GlobalFreeze(_owner,_expirationTimestamp);
    }
  
    
    function unFreezeGlobal( address _facetAddress) internal {
        FreezeStorage storage fs = freezeStorage();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        LibOwnership.OwnershipStorage storage os = LibOwnership.ownershipStorage();   

        //bytes4[] memory _cachedSelectors = fs.freezeCachedSelectors;
        address _owner = os.contractOwner;
        LibOwnership.isContractOwner(_owner);
        require(!isFrozenGlobal(),"Freeze duration hasn't expired yet.");

        address[] memory facetAddresses = ds.facetAddresses;
        for(uint16 i; i < facetAddresses.length; i++){
            if( facetAddresses[i] != _facetAddress ){
                bytes4[] memory _facetSelectors = ds.facetFunctionSelectors[ facetAddresses[ i ] ].functionSelectors;
                for ( uint16 ii; ii < _facetSelectors.length; ii++){  
                    ds.selectorToFacetAndPosition[ _facetSelectors[ii] ].facetAddress = facetAddresses[i];
                    //fs.facetFreezeAddress[ _facetSelectors[ii] ] = address(0);
                } 
            }
        }

        emit GlobalUnFreeze(_owner);
    }

    function extendFreezeGlobal(uint256 _freezeDuration) internal {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        LibOwnership.OwnershipStorage storage os = LibOwnership.ownershipStorage();   

        FreezeStorage storage fs = freezeStorage();
        address _owner = os.contractOwner;
        uint256 _expireTimestamp;
        require(!isFrozenGlobal(),"Freeze duration hasn't expired yet.");
        LibOwnership.isContractOwner(_owner);
        _expireTimestamp = fs.frozenGlobalExpire + _freezeDuration;
        
        fs.frozenGlobalExpire = _expireTimestamp;
        emit GlobalFreeze(_owner, _expireTimestamp);
    }
    function freezeDurationGlobal() internal view returns (uint256 freezeExpire_){
        freezeExpire_ = freezeStorage().frozenGlobalExpire;
    }
    function isFrozenGlobal() internal view returns (bool isFrozenGlobal_){
        FreezeStorage storage fs = freezeStorage();
        isFrozenGlobal_ = block.timestamp < fs.frozenGlobalExpire ; 
    }
    
  
    
}