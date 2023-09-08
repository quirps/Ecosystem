const FACETS = [
    'DiamondCutFacet', 'DiamondLoupeFacet', 'ERC1155', 'ERC1155Transfer', 'FreezeGlobal', 'FreezeOwner', 'MemberRegistry',
    'Members', 'Moderator', 'OwnershipFacet', 'Sales', 'TicketRedeemFacet'
]
const INITALIZE = [
    ['ERC1155', 'mint()'],
    ['MemberRegistry','initializor()'],
    ['Members','intialization()'],
    
]
module.exports = {FACETS}

//How to communicate intialization information, to whom or what?
//User should be communicated that certain items are required/needed for certain features to work
//This notification will be determined by database knowing which facet's need to be initialized. 
//The frontend will have notifications which will link to appropriate methods. 
//So information to be stored
/**
 * Checklist
 * ✅ DiamondCutFacet
 * ✅ DiamondLoupeFacet
 * ✅ ERC1155
 * ✅ ERC1155Transfer
 * ✅ FreezeGlobal
 * ✅ FreezeOwner
 * ❌ MemberRegistry
 * ❌ Members
 * ❌ Moderator
 * ✅ OwnershipFacet
 * ✅ Sales
 * ❌ TicketRedeem
 * 
 * 
 */