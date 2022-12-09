/* global describe it before ethers */

const {
    getSelectors,
    FacetCutAction,
    removeSelectors,
    findAddressPositionInFacets
  } = require('../scripts/libraries/diamond.js')

  const { deployDiamond } = require('../scripts/deploy.js')
  const { deployFrozenOwner } = require('../scripts/deployFrozenOwner.js')
  const { ethers } = require("hardhat");
  const { assert, expect } = require('chai');
  const { hexStripZeros } = require('ethers/lib/utils.js');

  
  describe('FrozenOwnerDiamondTest', async function () {
    let diamondAddress
    let frozenOwnerCut
    let tx
    let receipt
    let result
    let owner = ethers.Wallet.fromMnemonic('test test test test test test test test test test test junk')
    const addresses = []
  
    before(async function () {
      diamondAddress = await deployDiamond()
      await deployFrozenOwner(diamondAddress)
      frozenOwnerCut = await ethers.getContractAt('IFreezeOwner', diamondAddress)
    })
  
    it('Try unfreezeOwner when not in frozen state', async () => {
         await expect( frozenOwnerCut.unFreezeOwner({gas:800000}) )
         .to.be.revertedWith("Cannot UnfreezeOwner when not in frozen owner state") ;
        
    })
  
    it('Frozen Owner address should be contract owner address, expire timestamp block.timestamp \
    plus 2 seconds', async () => {
      let _freezeDuration = 2
      let _expireTime;
      let _expireTimeChain;
      let _frozenOwner;
      let _diamondOwner; 
      let _frozenOwnerSecond;
      let _ownershipFacetCut;
      console.log(hre.network.name)
        
      _ownershipFacetCut = await ethers.getContractAt('OwnershipFacet', diamondAddress)

      let tx_freezeOwner = await frozenOwnerCut.freezeOwner(2,{ gasLimit: 800000 });
      const block = await hre.network.provider.send("eth_getBlockByNumber",["latest",true])
      blockTimestamp = parseInt(block.timestamp)
      _expireTime = blockTimestamp + _freezeDuration

      _expireTimeChain = await frozenOwnerCut.callStatic.freezeExpireOwner();
      assert(_expireTime == _expireTimeChain,"Frozen Owner expiration timestamp must equal \
      block.timestamp + _freezeDuration ")
      //freeze owner expire time, block.timestamp + freezeDuration
      //freeze owner address = contract owner.

      _frozenOwner = await frozenOwnerCut.callStatic.getFreezeOwner();
     _ownerAddress = owner.address
     assert(_frozenOwner == _ownerAddress ,"Frozen owner must equal diamond owner's\
     address")
      
     await new Promise(resolve => setTimeout(resolve, _freezeDuration));
     let tx_UnFreeze = await frozenOwnerCut.unFreezeOwner({gasLimit:800000})
     _frozenOwnerSecond = await frozenOwnerCut.callStatic.getFreezeOwner();
     _diamondOwner = await _ownershipFacetCut.callStatic.owner();
     assert(_frozenOwnerSecond == ethers.constants.AddressZero )
     assert(_diamondOwner == owner.address )
    console.log(3)
    })
  
    it('Freeze for 1 second, extend for 3 seconds, try to unfreeze, try transferOwnership', async () => {
        let _ownershipFacetCut;
        let _diamondFacetCut;
        _ownershipFacetCut = await ethers.getContractAt('OwnershipFacet', diamondAddress)
        _diamondFacetCut = await ethers.getContractAt('DiamondCutFacet', diamondAddress)
        let tx_freezeOwner = await frozenOwnerCut.freezeOwner(2,{ gasLimit: 800000 });
        let tx_extendFreezeOwner = await frozenOwnerCut.extendFreezeOwner(4,{ gasLimit: 800000 });
        await expect( _ownershipFacetCut.transferOwnership(ethers.constants.AddressZero,{ gasLimit: 800000 }) )
        .to.be.revertedWith("LibDiamond: Must be contract owner")
       
    })
  
    it('should add test1 functions', async () => {
      const Test1Facet = await ethers.getContractFactory('Test1Facet')
      const test1Facet = await Test1Facet.deploy()
      await test1Facet.deployed()
      addresses.push(test1Facet.address)
      const selectors = getSelectors(test1Facet).remove(['supportsInterface(bytes4)'])
      tx = await diamondCutFacet.diamondCut(
        [{
          facetAddress: test1Facet.address,
          action: FacetCutAction.Add,
          functionSelectors: selectors
        }],
        ethers.constants.AddressZero, '0x', { gasLimit: 800000 })
      receipt = await tx.wait()
      if (!receipt.status) {
        throw Error(`Diamond upgrade failed: ${tx.hash}`)
      }
      result = await diamondLoupeFacet.facetFunctionSelectors(test1Facet.address)
      assert.sameMembers(result, selectors)
    })
  
    it('should test function call', async () => {
      const test1Facet = await ethers.getContractAt('Test1Facet', diamondAddress)
      await test1Facet.test1Func10()
    })
  
    it('should replace supportsInterface function', async () => {
      const Test1Facet = await ethers.getContractFactory('Test1Facet')
      const selectors = getSelectors(Test1Facet).get(['supportsInterface(bytes4)'])
      const testFacetAddress = addresses[3]
      tx = await diamondCutFacet.diamondCut(
        [{
          facetAddress: testFacetAddress,
          action: FacetCutAction.Replace,
          functionSelectors: selectors
        }],
        ethers.constants.AddressZero, '0x', { gasLimit: 800000 })
      receipt = await tx.wait()
      if (!receipt.status) {
        throw Error(`Diamond upgrade failed: ${tx.hash}`)
      }
      result = await diamondLoupeFacet.facetFunctionSelectors(testFacetAddress)
      assert.sameMembers(result, getSelectors(Test1Facet))
    })
  
    it('should add test2 functions', async () => {
      const Test2Facet = await ethers.getContractFactory('Test2Facet')
      const test2Facet = await Test2Facet.deploy()
      await test2Facet.deployed()
      addresses.push(test2Facet.address)
      const selectors = getSelectors(test2Facet)
      tx = await diamondCutFacet.diamondCut(
        [{
          facetAddress: test2Facet.address,
          action: FacetCutAction.Add,
          functionSelectors: selectors
        }],
        ethers.constants.AddressZero, '0x', { gasLimit: 800000 })
      receipt = await tx.wait()
      if (!receipt.status) {
        throw Error(`Diamond upgrade failed: ${tx.hash}`)
      }
      result = await diamondLoupeFacet.facetFunctionSelectors(test2Facet.address)
      assert.sameMembers(result, selectors)
    })
  
    it('should remove some test2 functions', async () => {
      const test2Facet = await ethers.getContractAt('Test2Facet', diamondAddress)
      const functionsToKeep = ['test2Func1()', 'test2Func5()', 'test2Func6()', 'test2Func19()', 'test2Func20()']
      const selectors = getSelectors(test2Facet).remove(functionsToKeep)
      tx = await diamondCutFacet.diamondCut(
        [{
          facetAddress: ethers.constants.AddressZero,
          action: FacetCutAction.Remove,
          functionSelectors: selectors
        }],
        ethers.constants.AddressZero, '0x', { gasLimit: 800000 })
      receipt = await tx.wait()
      if (!receipt.status) {
        throw Error(`Diamond upgrade failed: ${tx.hash}`)
      }
      result = await diamondLoupeFacet.facetFunctionSelectors(addresses[4])
      assert.sameMembers(result, getSelectors(test2Facet).get(functionsToKeep))
    })
  
    it('should remove some test1 functions', async () => {
      const test1Facet = await ethers.getContractAt('Test1Facet', diamondAddress)
      const functionsToKeep = ['test1Func2()', 'test1Func11()', 'test1Func12()']
      const selectors = getSelectors(test1Facet).remove(functionsToKeep)
      tx = await diamondCutFacet.diamondCut(
        [{
          facetAddress: ethers.constants.AddressZero,
          action: FacetCutAction.Remove,
          functionSelectors: selectors
        }],
        ethers.constants.AddressZero, '0x', { gasLimit: 800000 })
      receipt = await tx.wait()
      if (!receipt.status) {
        throw Error(`Diamond upgrade failed: ${tx.hash}`)
      }
      result = await diamondLoupeFacet.facetFunctionSelectors(addresses[3])
      assert.sameMembers(result, getSelectors(test1Facet).get(functionsToKeep))
    })
  
    it('remove all functions and facets except \'diamondCut\' and \'facets\'', async () => {
      let selectors = []
      let facets = await diamondLoupeFacet.facets()
      for (let i = 0; i < facets.length; i++) {
        selectors.push(...facets[i].functionSelectors)
      }
      selectors = removeSelectors(selectors, ['facets()', 'diamondCut(tuple(address,uint8,bytes4[])[],address,bytes)'])
      tx = await diamondCutFacet.diamondCut(
        [{
          facetAddress: ethers.constants.AddressZero,
          action: FacetCutAction.Remove,
          functionSelectors: selectors
        }],
        ethers.constants.AddressZero, '0x', { gasLimit: 800000 })
      receipt = await tx.wait()
      if (!receipt.status) {
        throw Error(`Diamond upgrade failed: ${tx.hash}`)
      }
      facets = await diamondLoupeFacet.facets()
      assert.equal(facets.length, 2)
      assert.equal(facets[0][0], addresses[0])
      assert.sameMembers(facets[0][1], ['0x1f931c1c'])
      assert.equal(facets[1][0], addresses[1])
      assert.sameMembers(facets[1][1], ['0x7a0ed627'])
    })
  
    it('add most functions and facets', async () => {
      const diamondLoupeFacetSelectors = getSelectors(diamondLoupeFacet).remove(['supportsInterface(bytes4)'])
      const Test1Facet = await ethers.getContractFactory('Test1Facet')
      const Test2Facet = await ethers.getContractFactory('Test2Facet')
      // Any number of functions from any number of facets can be added/replaced/removed in a
      // single transaction
      const cut = [
        {
          facetAddress: addresses[1],
          action: FacetCutAction.Add,
          functionSelectors: diamondLoupeFacetSelectors.remove(['facets()'])
        },
        {
          facetAddress: addresses[2],
          action: FacetCutAction.Add,
          functionSelectors: getSelectors(ownershipFacet)
        },
        {
          facetAddress: addresses[3],
          action: FacetCutAction.Add,
          functionSelectors: getSelectors(Test1Facet)
        },
        {
          facetAddress: addresses[4],
          action: FacetCutAction.Add,
          functionSelectors: getSelectors(Test2Facet)
        }
      ]
      tx = await diamondCutFacet.diamondCut(cut, ethers.constants.AddressZero, '0x', { gasLimit: 8000000 })
      receipt = await tx.wait()
      if (!receipt.status) {
        throw Error(`Diamond upgrade failed: ${tx.hash}`)
      }
      const facets = await diamondLoupeFacet.facets()
      const facetAddresses = await diamondLoupeFacet.facetAddresses()
      assert.equal(facetAddresses.length, 5)
      assert.equal(facets.length, 5)
      assert.sameMembers(facetAddresses, addresses)
      assert.equal(facets[0][0], facetAddresses[0], 'first facet')
      assert.equal(facets[1][0], facetAddresses[1], 'second facet')
      assert.equal(facets[2][0], facetAddresses[2], 'third facet')
      assert.equal(facets[3][0], facetAddresses[3], 'fourth facet')
      assert.equal(facets[4][0], facetAddresses[4], 'fifth facet')
      assert.sameMembers(facets[findAddressPositionInFacets(addresses[0], facets)][1], getSelectors(diamondCutFacet))
      assert.sameMembers(facets[findAddressPositionInFacets(addresses[1], facets)][1], diamondLoupeFacetSelectors)
      assert.sameMembers(facets[findAddressPositionInFacets(addresses[2], facets)][1], getSelectors(ownershipFacet))
      assert.sameMembers(facets[findAddressPositionInFacets(addresses[3], facets)][1], getSelectors(Test1Facet))
      assert.sameMembers(facets[findAddressPositionInFacets(addresses[4], facets)][1], getSelectors(Test2Facet))
    })
  })
  