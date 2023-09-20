const ethers = require('ethers')

/**
 * 
 * @param {uint8} amountAccounts 
 * @param {uint256[]} amounts 
 */
const DEFAULT_ETH_AMOUNT =  '45728182267703928635086400'
function generateHardhatAccounts(amountAccounts, amounts){
    const configOutput = []
    
    for( let i =0; i < amountAccounts; i++){
            amount = amounts[i] ||  DEFAULT_ETH_AMOUNT
        configOutput.push( {'privateKey' : (new ethers.Wallet.createRandom()).privateKey,
                            'balance': DEFAULT_ETH_AMOUNT
        
    }
        )
}
console.log(configOutput)
return configOutput
}
/**
 * 
 * @param {ConfigObject} config 
 * @param {Signer[]} signers 
 */
function configInitialize(config,signers){
    config.ticketDistributions.forEach( (dist,ind) =>{
        for(let i = 0; i < dist.length; i++ ){
            dist[i].address = signers[ind].address
        }
    })
}

/**
 * 
 * @param {Struct} dist
 * @returns {(address,uint256,uint256)[]} 
 */
function configToBatchParam(dists){
    const ids = []
    const amounts = []
    for(let dist of dists){
        ids.push(dist.ticketId)
        amounts.push(dist.amount)
    }
    return [dists[0].address, ids, amounts, ethers.utils.toUtf8Bytes("")]
}

module.exports = {generateHardhatAccounts, configInitialize, configToBatchParam}; 