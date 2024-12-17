const { ethers } = require('hardhat')
const { faker } = require('@faker-js/faker')

import type { TicketBalance, UserConfig, UserEcosystemConfig } from "../types/deploy/userConfig";
import type { EcosystemConfig } from "../types/deploy/userConfig";

const INITIAL_TOKEN_BALANCE : BigInt = BigInt( "10000000000000000000000000000" ) //10**30
const MAX_TICKET_RANGE : string = '100'
export const NUM_USERS : number = 20;
const tickets = (INITIAL_TOKEN_BALANCE: BigInt): TicketBalance[] => 
    Array.from({ length: parseInt(MAX_TICKET_RANGE) }, (_, i) => ({
        id: BigInt( i + 1 ),
        amount: INITIAL_TOKEN_BALANCE
    }));

export async function randomUserConfig( numUsers : number ){
    let userConfigData : UserConfig[] = []; 
    const signers = await ethers.getSigners()
    //number of owners is equal to number of ecosystems
    const ecosystemNames = ['Ecosystem1', 'Ecosystem2', 'Ecosystem3']
    let signerInd : number = 0;
    let ecosystemConfigData : EcosystemConfig[] = ecosystemNames.map( (name)=> {
        let _ecosystemConfig = {
            name, 
            'version':'0.0.0', 
            'owner': signers[ signerInd ] 
        };
        signerInd++;
        return _ecosystemConfig;

    }) 

    for( let userIndex = 0; userIndex < numUsers; userIndex++){
        //const userConfig : UserConfig = {user : signers[ signerInd ]};
        const userEcosystemConfigs : UserEcosystemConfig[] = [];
         for(let ecosystemIndex = 0; ecosystemIndex < ecosystemNames.length; ecosystemIndex++){
             let ecosystemConfig : UserEcosystemConfig = {
                    ecosystemName : ecosystemNames[ ecosystemIndex ],
                    tokens : INITIAL_TOKEN_BALANCE,
                    tickets : tickets(INITIAL_TOKEN_BALANCE),
                    swapPermissions : true,
                    exchangePermissions : true,
                    registeredName : faker.internet.userName(),
                    moderator : Math.floor(Math.random() * 21),
                    membershipLevel: Math.floor(Math.random() * 15)
             }
             userEcosystemConfigs.push( ecosystemConfig )
         }
         userConfigData.push( {user : signers[ signerInd ], userEcosystemConfigs} );
         signerInd ++;  
    }
    return { userConfigData, ecosystemConfigData} 
  }


