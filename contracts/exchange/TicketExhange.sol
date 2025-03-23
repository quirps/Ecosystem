pragma solidity ^0.8.9;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol"; 
import {IERC1155Transfer} from "../facets/Tokens/ERC1155/interfaces/IERC1155Transfer.sol";
import {IERC1155} from "../facets/Tokens/ERC1155/interfaces/IERC1155.sol";
import {IERC20} from "../facets/Tokens/ERC20/interfaces/IERC20.sol";
import "./ExchangeRewardPool.sol";
 
 
contract MassDX is  ExchangeRewardPool{  
    address public  massDXProtocol;   
 
    // per
    uint24 constant PERCENTAGE_BASE =             1000000; 
    uint24 MASSDX_PROTOCOL_FEE_PERCENTAGE =  10000; //1%
    uint24 public TIME_POOL_FEE_PERCENTAGE =        2000; //0.2%
    uint64 constant STAKE_PRECISION_HELPER = type(uint64).max; // used as a placeholder before calculating stake rewards 
                                                               // during division to maintain precision
    //Auction
    uint24 MIN_BID_INCREASE =               30000; //3%
    mapping(uint96 => TicketSale) public ticketSale;
    

    enum SaleStatus {NonExistent, Available, Sold, Cancelled}
    enum AuctionStatus {Ongoing, Completed, Cancelled, Overtime}

    event SaleCreated(TotalSale);
    event SaleCancelled(uint96);
    event SaleExecuted(uint96 saleId, uint256 ticketAmount, address buyer, uint256 sellerFee, uint256 timePoolTokensMinted );
    
    struct TicketSale{
       address ticketAddress;
        uint256 ticketId;
        uint256 ticketAmount;
        address tokenAddress;
        uint256 tokenAmountPerTicket;
       SaleStatus status;
       address sellerAddress;
    }
    struct TotalSale {
        uint96 saleId;
        SaleInput sale;
    }
    struct SaleInput{
        address ticketAddress;
        uint256 ticketId;
        uint256 ticketAmount;
        uint256 tokenAmountPerTicket;
        address tokenAddress;
    }
    struct Auction {
        uint96 auctionId;
        SaleInput sale;
        AuctionParams params;
        
    }
    struct AuctionParams{
        uint32 expirationTime; 
        uint256 buyNow;
        uint256 minimumBid;
    }

    constructor( address _exchangeRewardERC1155 ) ExchangeRewardPool( _exchangeRewardERC1155){
        massDXProtocol = msgSender();
    }
    function sellTickets( TotalSale[] memory _tickets) external {
        for(uint ticketIndex; ticketIndex < _tickets.length; ticketIndex ++){
            sellTicket(_tickets[ticketIndex]);
        }
    }

    //User's can sell for reward tokens, but it won't gain rewards due to not implementing ERC20
    /**
     * 
     * @param _ticket ticket(s) for sale
     * @dev ticket price is price per ticket. 
     */
    function sellTicket( TotalSale memory _ticket) public {
        //assert unused ticketId
        require( ticketSale[ _ticket.saleId ].status == SaleStatus.NonExistent, "Must generate a unique sale id");
        require( _ticket.sale.ticketAmount > 0, "Must sell a non-zero amount of tickets");
        
        //transfer tickets to exchange 
        IERC1155Transfer(_ticket.sale.ticketAddress).safeTransferFrom(msgSender(), address(this), _ticket.sale.ticketId, _ticket.sale.ticketAmount,""); 
 
        //set valid sale
        
        ticketSale[ _ticket.saleId ] = TicketSale(
            _ticket.sale.ticketAddress, 
            _ticket.sale.ticketId,
            _ticket.sale.ticketAmount,
            _ticket.sale.tokenAddress,
            _ticket.sale.tokenAmountPerTicket,
            SaleStatus.Available,
            msgSender()
        );
        emit SaleCreated(_ticket);
    }

    function cancelSale (uint96 _saleId) public {
        TicketSale storage _ticketSale = ticketSale[_saleId];
        require(msgSender() == _ticketSale.sellerAddress, "Must be the seller to cancel this sale"); 
        IERC1155Transfer(_ticketSale.ticketAddress).safeTransferFrom( address(this), msgSender(), _ticketSale.ticketId, _ticketSale.ticketAmount,""); 
  
        _ticketSale.status = SaleStatus.Cancelled;
        emit SaleCancelled(_saleId);
    }

    /**
     * @param _saleId id of the sale
     * @param _ticketAmount  amount of tickets to purchase from this sale
     * @dev buys a ticket from a given sale ID. 
     * 
     */
    function buyTickets(uint96 _saleId, uint256 _ticketAmount) public {
        uint256 _mintAmount; 
        uint256 _sellerFee;
        uint256 _massDXProtocolFee;
        uint256 _timePoolFee;
        address _tokenAddress;
        //approaching stack too deep limit, don't unpack variables
        TicketSale storage _ticketSale = ticketSale[_saleId];
        _tokenAddress = _ticketSale.tokenAddress;
        //assert valid sale conditions
        require(_ticketAmount <= _ticketSale.ticketAmount, "Unable to purchase more tickets than are currently available.");
        require(_ticketSale.status == SaleStatus.Available,"Sale isn't available anymore.");

        //transfer tickets/currency
         
        uint256 _totalCost = _ticketAmount * _ticketSale.tokenAmountPerTicket;

        //transfer protocol fee 
        _massDXProtocolFee = ( _totalCost * MASSDX_PROTOCOL_FEE_PERCENTAGE )/PERCENTAGE_BASE;
        IERC20(_tokenAddress).transferFrom(msgSender(), massDXProtocol, _massDXProtocolFee);
        //time pool fee
        _timePoolFee = ( _totalCost * TIME_POOL_FEE_PERCENTAGE )/PERCENTAGE_BASE;
        IERC20(_tokenAddress).transferFrom(msgSender(), address(this), _timePoolFee);

        //updates the following:
        // activate this timeslots bitmap position if not done so already
        // total earning /sum ratio locally and globally 
        updateRewardsData(_tokenAddress, _timePoolFee);
        
        
        //transfer currency to seller
        _sellerFee = _totalCost - _massDXProtocolFee - _timePoolFee; 
        IERC20(_tokenAddress).transferFrom(msgSender(), _ticketSale.sellerAddress, _sellerFee );
        //transfer ticket to buyer
        IERC1155Transfer(_ticketSale.ticketAddress).safeTransferFrom( address(this), msgSender(), _ticketSale.ticketId, _ticketAmount,"");
        
        //generate time pool reward tokens
        //the reward token is purely relative to it's exchange counterpart, hence we can simply take a 
        //1:1 correspondence of the sale amount as the base conversion of  a transaction to reward amount
        //but since we want to implement erc1155, that implies allowing the purchase of tickets via reward tokens
        //users could then double their rewards by simply buying an item
        //issue has to do with minting on purchase. 
        //but it wouldnt be an issue if a new reward token for the reward token was created, but that's getting out
        //scope
        _mintAmount = _totalCost;
        //exchange token addresses are mapped directly to erc1155 reward ids
        IERC1155( exchangeRewardERC1155 ).mint(_ticketSale.sellerAddress,uint256(uint160(_tokenAddress)), _mintAmount,"");
         
        //update sale information
        uint256 _newTicketAmount = _ticketSale.ticketAmount - _ticketAmount;
        if( _newTicketAmount == 0 ){
            _ticketSale.status = SaleStatus.Sold;
        }
        _ticketSale.ticketAmount -= _ticketAmount;

        emit SaleExecuted(_saleId, _ticketAmount, msgSender(), _sellerFee, _mintAmount);
        //assert 

         
    }
 
 
    
    // function createAuction() external {

    // }
    // function cancelAuction() external{

    // }

    // function bid() external {

    // }
    
}




