pragma solidity ^0.8.9;

/**
 * Here we want to capture a sales of tickets/ticket bundles, which comprise of a
 * purchase (an id and quantiity) and results in a product( id[] and quantity[]).
 * 
 * Out of the box attributes:
 *  Limited Time Sales
 *  Limited Bundles
 *  Conditional Bundles
 *  Rank Tiered
 *  Rank Exclusive
 *  Member Exclusive
 */

/**
 * Tiered Bundle
 *  Bundle Limit per tier
 * Rank Tiered
 *  -Read total number of tickets, mint
 *  -
 */
contract Sales{
    Sales[] sale;
    mapping( id => Sales) idToSale;
    struct Bundle{
        uint256[] rewardIds;
        uint256[] rewardAmounts;
        uint256   costId;
        uint256   costAmount;
    }   

    struct TieredBundle{
        Bundle[] bundleTier;
        uint16 index;
    }
    struct rankedSale{
        RankTier[] rankTiers;
        uint96 expirationTimestamp;
    }
    struct RankTier{
        uint32 ticketLimit;
        uint32 bundleLimit;
        uint96 timeIndex; 
        RankLabel rankLabel;
        Bundle bundle;
    }

    struct TimeDelay{
        uint96[] timestampExpire;
    }

    /**
     * Rank Tiered
     *  1. Mint on demand
     *  2. Begin access for top ranked indiviudals, individual bundles, bundle limit
     *  3. 
     */
     
    function intiateTieredSale(TieredBundle memory _tieredBundle) external {

    }
    //Rank tiered, limited bundles per tier
    /**
     * Flow is the following:
     *  1. Highest rank goes first with the allotted bundles.
     * 2. 
     */
    function initiateRankedLimitedSale(RankedSale memory _rankedSale) external {
        //setId map to sale
    }
}