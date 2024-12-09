
const {ethers}  = require('hardhat');
import type {Signer} from "ethers"
import type { EthereumAddress } from "../web3";

export type UserConfig = {
    user : Signer,
    userEcosystemConfigs : UserEcosystemConfig[]
}

export type UserEcosystemConfig = {
    ecosystemName : string,
    tokens : BigInt,
    membershipLevel : number,
    tickets : TicketBalance[],
    swapPermissions : boolean,
    exchangePermissions : boolean,
    registeredName : string,
    moderator : number,
    
}

export type EcosystemConfig = {
    name : string,
    version : string,
    owner : Signer,
}

export enum StakeInterval {
    Continious = 0,
    Threeday = 1,
    SevenDay = 2,
    TwentyEightDay = 3
}
export type Stake = {
    amount : BigInt,
    stakeDuration : StakeInterval
}
export type TicketBalance = {
    id : BigInt,
    amount : BigInt
}


