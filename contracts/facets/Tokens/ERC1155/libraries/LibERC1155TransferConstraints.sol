pragma solidity ^0.8.9;

import {LibMemberLevel} from "../../../MemberLevel/LibMemberLevel.sol";
library LibERC1155TransferConstraints {
    bytes32 constant ERC1155_CONSTRAINT_STORAGE_POSITION = keccak256("diamond.erc1155constraints");

    struct ConstraintStorage {
        mapping(uint256 => bool) transferrable;
        mapping(uint256 => int64) minimumMemberLevel;
        mapping(uint256 => bool) isMembershipLevelActive;
        mapping(uint256 => uint32) expireTime;
        mapping(uint256 => uint24) royaltyFee;
        mapping(uint128 => uint128) ticketIntervalNonce;
    }

    function erc1155ConstraintStorage() internal pure returns (ConstraintStorage storage cs) {
        bytes32 position = ERC1155_CONSTRAINT_STORAGE_POSITION;
        assembly {
            cs.slot := position
        }
    }
    uint256 constant INTERVAL_SIZE = 2 ** 128;
    uint256 constant NUMBER_INTERVALS = 2 ** 128; // max 60 constraints
    uint8 constant CURRENT_MAX_INTERVALS = 8;
    struct Constraints {
        bool isTransferable;
        int64 minimumMembershipLevel;
        bool isMembershipLevelActive;
        uint32 expireTime;
        uint24 royaltyFee;
    }

    function _ticketConstraints(uint256 _ticketId) internal view returns (Constraints memory constraints_){
        ConstraintStorage storage cs = erc1155ConstraintStorage();
        constraints_ = Constraints( 
            cs.transferrable[ _ticketId],
            cs.minimumMemberLevel[ _ticketId],
            cs.isMembershipLevelActive[ _ticketId],
            cs.expireTime[ _ticketId],
            cs.royaltyFee[ _ticketId]
        );
    }

}
