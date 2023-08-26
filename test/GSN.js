const { RelayProvider } = require('@opengsn/provider')
const { GsnTestEnvironment } = require('@opengsn/dev' )
const ethers = require('ethers')
const { it, describe, before } = require('mocha')
const { assert } = require('chai')

const Web3HttpProvider = require( 'web3-providers-http')

//we still use truffle compiled files
const Counter = require('../artifacts/contracts/facets/Counter.sol/Counter')

describe('using ethers with OpenGSN', () => {
    let counter
    let accounts
    let web3provider
    let from
    before(async () => {
	let env = await GsnTestEnvironment.startGsn('localhost')

	const { paymasterAddress, forwarderAddress } = env.contractsDeployment
    
    const web3provider = new Web3HttpProvider('http://localhost:8545')
    
    const deploymentProvider= new ethers.providers.Web3Provider(web3provider)
    
        const factory = new ethers.ContractFactory(Counter.abi, Counter.bytecode, deploymentProvider.getSigner())
        
        counter = await factory.deploy(forwarderAddress)

        await counter.deployed()

        const config = await {
            // loggerConfiguration: { logLevel: 'error'},
            paymasterAddress: paymasterAddress,
            auditorsCount: 0
        }
        // const hdweb3provider = new HDWallet('0x123456', 'http://localhost:8545')
        let gsnProvider = RelayProvider.newProvider({provider: web3provider, config})
    	await gsnProvider.init()
	   // The above is the full provider configuration. can use the provider returned by startGsn:
        // const gsnProvider = env.relayProvider

    	const account = new ethers.Wallet(Buffer.from('1'.repeat(64),'hex'))
        gsnProvider.addAccount(account.privateKey)
    	from = account.address

        // gsnProvider is now an rpc provider with GSN support. make it an ethers provider:
        const etherProvider = new ethers.providers.Web3Provider(gsnProvider)

        counter = counter.connect(etherProvider.getSigner(from))
    })

    describe('make a call', async () => {
        let counterChange
        let balanceUsed
        before(async () => {
            const countBefore = await counter.counter()
            await counter.increment( {gasLimit: 1e6})
            const countAfter = await counter.counter()
            counterChange = countAfter - countBefore
        })

        it('should make a call (have counter incremented)', async () => {

            assert.equal(1, counterChange)
        })

        it('should not pay for gas (balance=0)', async () => {
            assert.equal(0, await counter.provider.getBalance(from))
        })

        it('should see the real caller', async () => {
            assert.equal(from.toLowerCase(), (await counter.lastCaller()).toLowerCase())
        });
    })
})