const { ethers } = require('hardhat')
import type {Signer} from "ethers"
import { UserEcosystemConfig, UserConfig, TicketBalance} from "../../types/deploy/userConfig";
const { ECOSYSTEM_CURRENCY_ID } = require("../../constants");
import type { LibMembers } from "../../types/ethers-contracts/Ecosystem";

export async function userConfig( _userConfigs : UserConfig[], ecosystems : any , exchangeAddress: string, swapAddress : string){
    const populateTxs : Promise<any>[] = []
    for( let userConfig of _userConfigs ){
        //inline await is just to unwrap the array promise
        populateTxs.push( ... await userPopulate( userConfig, ecosystems, exchangeAddress, swapAddress ) );
    }
    console.log("Finished user config, now await");
    try {
        await Promise.all(populateTxs);
    } catch (error) {
        console.error("Error during transaction execution:", error);
    }
    console.log("Users configured!");
    //iterate through ecosystems for each user and initialize them
    //deploy swaps
}


/**
 * this can be gas optimized by using batch calls.
 * note th
 */
async function userPopulate( userConfig : UserConfig , ecosystems: any, exchangeAddress: string, swapAddress : string) : Promise<Promise<any>[]> {
    const user : Signer = userConfig.user;
    const userAddress : string = await user.getAddress();

    const txs : Promise<any>[] = [];
    for( let ecosystemConfig of userConfig.userEcosystemConfigs ){
        
        //connect owner to ecosystem
        let _ecosystem = ecosystems[ ecosystemConfig.ecosystemName ]
        let ecosystemOwner = _ecosystem.connect( _ecosystem.owner )

        // mint tokens 
        try {
            console.log("Minting tokens...");
            txs.push(ecosystemOwner.mint(userAddress, ECOSYSTEM_CURRENCY_ID, ecosystemConfig.tokens, "0x"));
        } catch (error) {
            console.error("Error during mint tokens transaction:", error);
        }        //mint tickets
        const tickets : TicketBalance[] = ecosystemConfig.tickets;  
        const ticketIds = tickets.map( ticket => ticket.id)
        const ticketAmounts = tickets.map( ticket => ticket.amount)
        console.log("Passsed Mint")
        try {
            console.log("Minting tickets...");
            txs.push(ecosystemOwner.mintBatch(userAddress, ticketIds, ticketAmounts, "0x"));
        } catch (error) {
            console.error("Error during mint tickets transaction:", error);
        }        // assign membership levels
        const memberLeaf : LibMembers.LeafStruct = {
            memberAddress : userAddress,
            memberRank : {
                timestamp : Math.floor( Date.now() / 1000 ),
                rank : ecosystemConfig.membershipLevel
            }
        }
        try {
            console.log("Setting member rank...");
            txs.push( ecosystemOwner.setMemberRankOwner( [memberLeaf] ) )
        } catch (error) {
            console.error("Error during memberRank transaction:", error);
        } 
        // register name 
        const username : string = ecosystemConfig.registeredName;
        
        try {
            console.log("Setting member name in registry...");
            txs.push( ecosystemOwner.setUsernameOwner( [ username ], [ userAddress ] ) )
        } catch (error) {
            console.error("Error during member registry transaction:", error);
        } 
        // grant permissions 
        
        try {
            console.log("Setting priveleges...");
            !ecosystemConfig.exchangePermissions ||  txs.push( _ecosystem.setApprovalForAll( exchangeAddress, true ) );
            !ecosystemConfig.swapPermissions ||  txs.push( _ecosystem.setApprovalForAll( swapAddress, true ) );
        } catch (error) {
            console.error("Error during privelege setting transaction:", error);
        } 
        // assign moderator
        try {
            console.log("Setting user moderator rank...");
            txs.push( ecosystemOwner.setModeratorRank( userAddress, ecosystemConfig.moderator ) )
        } catch (error) {
            console.error("Error during moderator rank transaction:", error);
        } 
        console.log("One full cycle")
        // // assign stake
        // ecosystemConfig.stake.map()
        // _ecosystem.batchStake()
    }
    return txs;
}


/**
 * Want to configure n users. We can break it down into ecosystem-specific components and non.
 * 
 * Ecosystem Components:
 *  1. Tokens
 *  2. Membership Levels
 *  3. Tickets
 *  4. Permissions to Exchange
 *  5. Registered Name 
 *  6. Moderator 
 *  7. Stake 
 *  
 * Non Ecosystem Components:
 *  8. Swap Orders 
 *  9. Swap Related Stakes 
 *  10. Sale Orders 
 *  11. 
 * 
 *  User1 : {
 *   Ecosystesms: 
    *  [ 
    *      { 
    *         address : "0x1234567890abcdef1234567890abcdef1234567890",
    *         Tokens : 1000,
    *         MembershipLevel : 4,
        *      Tickets : {
        *        1 : 10,
        *        2 : 5,,
        *        3 :  6,
        *      },
        *      Permissions : [0x2D8389FA8...], // contracts that have permission to ecosystem erc1155
        *      RegisteredName : user1,
        *     Moderator : 4,
        *    Stake : [ {amount :1000, stakeDuration : 7day }
        *   }
        * 
    *  ]
    * ...
    * 
    * }
*  SwapOrders : [{
*      inputToken : { address : "0x1234567890abcdef1234567890abcdef1234567890",
*                       amount : 3040},
* 
*      outputToken : { address : "0x1234567890abcdef1234567890abcdef1234567890",
*                       },
*      ratio : 30400,
* }],
* 
* ....
 */