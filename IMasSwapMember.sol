pragma solidity ^0.8.0;


interface IMasSwapMembers{

    struct Checkpoint{
        address checkpointer;
        uint128 feeGrowthOutside0x128;
        uint128 feeGrowthOutside1x128;
    }
    struct CheckpointKeys{
        uint24 checkpointTimestamp;
        uint16 checkpointTick;
    }

    /// There is an allowed checkpoint per each block (uint24 blockTimestamp) 
    /// and each tick (uint16 tick)
    mapping( uint24 => mapping( uint16 => Checkpoint ) ) checkpoint;
    function setCheckpoint( uint16 tick) external;
    function getCheckpoints( CheckpointKeys[] checkpointKeys) external view returns 
            ( Checkpoint[] checkpoints_) ;

    struct Member{
        address userAddress;
        uint24 timestamp;
        bytes32 rankLabel;
        bytes32 username;
        bytes32 prevHash;
    }
    
    struct MemberProof{
        Member leaf;
        bytes32[] branches
    }
    
    ///@notice Member's whos rank is lowered after their initial liquidity
    ///        deposit potentially earn excess rewards, which can then be claimed
    ///         by a checkpointer/prover pair. 
    ///         Checkpointer - A checkpointer associates a timestamp with a given
    ///         tick and it's feeGrowthOutside0x128, feeGrowthOutside1x128. 
    ///         Provers - Reference a checkpoint that is after a time in which
    ///         a member is deranked, then proves the member's ranked history,
    ///         splitting any excess rewards with the checkpointer. 
    function claimForbiddenRewards(  MemberProof[] memberProof, CheckpointKeys[] )
} 