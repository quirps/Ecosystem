pragma solidity ^0.8.6;

library LibERC20{
    bytes32 constant ERC20_STORAGE_POSITION = keccak256("diamond.standard.erc20.storage");
    struct ERC20_Storage{
        mapping(address => uint256)  balances;

        mapping(address => mapping(address => uint256))  allowances;

        uint256 totalSupply;

        string name;
        string symbol;

    }

    function erc20Storage() internal pure returns (ERC20_Storage storage es){
        bytes32 ERC20_STORAGE_POSITION = ERC20_STORAGE_POSITION;
        assembly{
            es.slot := ERC20_STORAGE_POSITION
        }
    }
    
}