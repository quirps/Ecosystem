pragma solidity ^0.8.6;

library LibERC1155{
    bytes32 constant ERC1155_STORAGE_POSITION = keccak256("diamond.standard.erc1155.storage");
    struct ERC1155_Storage{
         // id => (owner => balance)
        mapping (uint256 => mapping(address => uint256)) balances;

        // owner => (operator => approved)
        mapping (address => mapping(address => bool))  operatorApproval;

    }

    function erc1155Storage() internal pure returns (ERC1155_Storage storage es){
        bytes32 ERC1155_STORAGE_POSITION = ERC1155_STORAGE_POSITION;
        assembly{
            es.slot := ERC1155_STORAGE_POSITION
        }
    }
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value)internal {
        ERC1155_Storage storage es =  erc1155Storage();
        // SafeMath will throw with insuficient funds _from
        // or if _id is not valid (balance will be 0)
        es.balances[_id][_from] = es.balances[_id][_from] - _value;
        es.balances[_id][_to]   = _value  + es.balances[_id][_to];
    }
    function balanceOf(address _owner, uint256 _id) internal view returns (uint256 amount_){
        ERC1155_Storage storage es =  erc1155Storage();
        
        amount_ = es.balances[_id][_owner];
    }

    
    function operatorApproval(address _from) internal view returns(bool operatorApproved_){
        ERC1155_Storage storage es =  erc1155Storage();
        operatorApproved_ = es.operatorApproval[_from][msg.sender];
    }
    function operatorApprovalAll(address _from, address _operator) internal view returns(bool operatorApproved_){
        ERC1155_Storage storage es =  erc1155Storage();
        operatorApproved_ = es.operatorApproval[_from][_operator];
    }
    function setOperatorApproval(address _operator, bool _approved) internal{
        ERC1155_Storage storage es =  erc1155Storage();
        es.operatorApproval[msg.sender][_operator] = _approved;
    }
}