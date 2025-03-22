pragma solidity ^0.8.28;
library LibERC2981 {
    
    bytes32 constant STORAGE_ERC2981 = "diamond.storage.ERC2981";

    struct ERC2981Storage {
        mapping(uint256 => uint256) royaltyFee; // tokenId -> royaltyFee
    } 

    function erc2981torage() internal pure returns (ERC2981Storage storage es_) {
        bytes32 storagePosition = STORAGE_ERC2981;
        assembly {
            es_.slot := storagePosition
        }
    }
}