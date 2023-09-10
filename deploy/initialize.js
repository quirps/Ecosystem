/**
 * Needs to initialize facets for test environment
 * 
 * Frontend will notifications when initialized, event based
 * Database stores whether user has initialized a particular facet
 */
/**
 * Explicitly write intiailziations for the initalizor constatns
 * Finish contracts and TESTS for those contracts
 * Integration tests (Paused)
 * 
 * Let's create DATABASE SCHEMA. NEED TO HOP BACK TO FRONTEND TO KEEP THINGS FRESH
 */
/**
 * Need initialization and actions
 * Initialization is moreso necessary to use an ecosystem and are common to all ecosystems
 * Actions are necessary to explore state space of ecosystems
 */

async function diamondInitialize(){
    //config 
}

diamondInitialize()
.then(() => process.exit(0))
.catch(error => {
  console.error(error)
  process.exit(1)
})

module.exports = {diamondInitialize}

/**
 * Seperate initialization from actions? 
 * Re-use these functions for frontend.
 * Just create initialize module and actions handled seperately
 * Wrapper for ecyosystem? config file wrapper an associated methods 
*/