pragma solidity ^0.8.28;

import {iOwnership} from "../Ownership/_Ownership.sol"; 
/**
 * @title 
 * @author 
 * @notice Tier permissions for various functionality on the ecosystem, enabling the 
 * ecosystem owner to have an easier time with management.  
 */
contract TieredPermission is iOwnership{
    enum PermissionType{ TicketCreator, TokenCreator, EventCreator, SaleCreator, EventDeployer, TicketDeployer, TokenDeployer,
    ModeratorManager, MembershipLevelManager }

    

    function isAppCreator( address creator ) external view returns (bool isAppCreator_){
        return  _ecosystemOwner() ==  creator;
    }
}