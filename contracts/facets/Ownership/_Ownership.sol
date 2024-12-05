// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibOwnership} from "./LibOwnership.sol";
import {iERC2771Recipient} from "../ERC2771Recipient/_ERC2771Recipient.sol";     

contract iOwnership is iERC2771Recipient {
    error MigrationAlreadyInitiated();
    error MigrationAlreadyCompleted();
    error MigrationNotInitiated();

    event MigrationInitiated(address initiatior, uint32 timeInitiatied);
    event MigrationCancelled(address cancellor, uint32 timeCancelled);

    modifier onlyOwner(){
        msgSender() == _ecosystemOwner();
        _;
    }
    function _setEcosystemOwner( address _newOwner) internal {
        isEcosystemOwnerVerification();
        LibOwnership._setEcosystemOwner(_newOwner);
    }

    function _ecosystemOwner() internal view returns (address owner_) {
        owner_ = LibOwnership._ecosystemOwner();
    }

    function isEcosystemOwnerVerification() internal view {
        require( msgSender() == _ecosystemOwner(), "Must be the Ecosystem owner"); 
    }
    

    //Migration related methods

    /**
     * @dev sole purpose is to restrict user from having access to ecosystem modularity
     * until they initiate a migration. only modular changes are done via registry until
     * then. 
     */
    function isEffectiveOwner() internal view {
        LibOwnership.OwnershipStorage storage os = LibOwnership.ownershipStorage();
        LibOwnership.Migration storage _migration = os.migration;
        if( _migration.isMigrating && isMigrationPeriodOver( _migration.initiationTimestamp ) ){
            require( msgSender() == os.ecosystemOwner, "Sender must be the owner.");
        }
        else{
            require(msgSender() == os.registry, "Sender must be from the registry.");
        }
    }

    
    /**
     * @dev start the migration 
     */
    function _initiateMigration() internal {
        LibOwnership.OwnershipStorage storage os = LibOwnership.ownershipStorage();
        LibOwnership.Migration storage _migration = os.migration;
        if( _migration.isMigrating ){
            revert MigrationAlreadyInitiated();
        }
        else{
            _migration.isMigrating = true;
            _migration.initiationTimestamp = uint32(block.timestamp);
            emit MigrationInitiated(msgSender(), uint32(block.timestamp) );
        } 
    }
    function _cancelMigration() internal {
        LibOwnership.OwnershipStorage storage os = LibOwnership.ownershipStorage();
        LibOwnership.Migration storage _migration = os.migration;
        uint32 _initiationTimestamp = _migration.initiationTimestamp;
        if( _migration.isMigrating  ) {
            if(isMigrationPeriodOver( _initiationTimestamp )){
                revert MigrationAlreadyCompleted();
            }
            else{
                _migration.isMigrating = false;
                emit MigrationCancelled(msgSender(), uint32(block.timestamp));
            }
        }
        else {
            revert MigrationNotInitiated();
        }
        
    }
    function isMigrationPeriodOver( uint32 _initiationTimestamp ) internal view returns (bool isOver_){
        isOver_ = uint32(block.timestamp) + LibOwnership.MIGRATION_TRANSITION_LOCK_TIMESPAN > _initiationTimestamp;
    }
}
 