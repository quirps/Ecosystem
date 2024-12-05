pragma solidity ^0.8.9;

import {IERC20} from "../facets/Tokens/ERC20/interfaces/IERC20.sol";
import {iOwnership} from "../facets/Ownership/_Ownership.sol";

import { IStake } from "./interfaces/IStake.sol";
import { IVersion } from "./interfaces/IVersion.sol";

/**
We want to allow for IPO purchasing and Internal Swapping 
(as opposed to swapping with other platforms).

 */
 //tokens can be simply ordered, so highest value will be numerator for the ratio, lowest is denominator
contract Swap is iOwnership{
    /**
        Sell a given token of type A for a given token of type B from 
        their respective ecosystems. 
      */
      uint256 constant PRECISION = 2^64;
      struct Swap{  
        address token;
        uint256 amount;
      }
      enum Direction {Down, Up}
      enum OrderFill {Partial, Full}
      struct Order{
        uint256 stakeId;
        address marketMaker;
        address outputToken; //the currency the market maker is expecting in return from their input currency swap
        Swap inputSwap; // currency the market maker inputted 
      }
        //upperAddress, lowerAddress, ratio
      mapping ( address => mapping(address => mapping( uint256 => Order ) ) )  orders;

      error MalOrderedArray(Direction direction, uint256[] targetOrders);
      
      event Fill(address inputSwap, address outputSwap, uint256 ratio, uint256 outputAmount, OrderFill orderFillType);
      event SwapOrderSubmitted(address swapIntiaitor, address inputSwapToken, address outputSwapToken, uint256 inputSwapAmount);
      event SwapCancelled(address marketMaker, uint256 ratio, uint256 amount );

    //one caveat is same block transactions will miss eachother (i.e. swaps that overlap in their ratio numbers)
    //won't see each other. There could be some potential off-chain method to combat this, but would involve guessing
    //transaction ordering, transaction inclusion. 



    //rentrancy guard;
    /**
     */
    /**
     * @dev Swaps from inputSwap token to outputSwap token via consuming valid targetOrders
     * @param inputSwap - The caller's currency intended to be swapped for the outputSwap's currency
     * @param outputSwap - The target currency the caller intends to swap for
     * @param targetOrders - An array of unique ratios (which is enforced by design) that correspond to various outputSwap orders
     * the inputSwap will consume if their inputSwap amount permits it.
     * @param _stakeId If inputSwap token is from a MassDX Ecosystem, whatever inputSwap.amount is left over will be staked at the 
     * ratio defined by inputSwap.amount * PRECISiON / outputSwap.amount
     * @param isOrder if true will create a swap order if any inputSwap.amount is leftover
     */
    function swap(Swap memory inputSwap, Swap memory outputSwap, uint256[] memory targetOrders, uint256 _stakeId, bool isOrder) external {
        bool isEcosystem; 

        // swap requirements
        require(inputSwap.token != outputSwap.token , "Can't swap into the same ERC20 token");
        require(inputSwap.amount * outputSwap.amount != 0 ,"Must have non-zero swap amounts.");


        //transfer sell amount from user to contract
        //IERC20(inputSwap.token).transferFrom( msgSender(), address(this), inputSwap.amount); 
        
        //want to store prices in mappings (i.e. price => SwapOrder )
        //Make each ratio unique, can only go from zero or SwapOrder and vice versa
        //Set a given spacing? Max resolution
        (Swap memory upperSwap, Swap memory lowerSwap, Direction direction) = swapOrdered(inputSwap, outputSwap);
        uint256 scaledRatio = ( inputSwap.amount * PRECISION ) / outputSwap.amount;


        //loop through target orders, already in decreasing/increasing order with respect to user's
        //input swap. 
        uint256 currentTargetRatio;
        for( uint256 orderIndex; orderIndex < targetOrders.length - 1; orderIndex ++){
            if(inputSwap.amount == 0){
                break;
            }
            uint256 newTargetRatio = targetOrders[ orderIndex ];
            //assert arrays are well ordered in the proper direction 
            if( direction == Direction.Down && currentTargetRatio < newTargetRatio ){  
                revert MalOrderedArray(direction, targetOrders);
            }
            else if ( direction == Direction.Up && currentTargetRatio > newTargetRatio){ 
                revert MalOrderedArray(direction, targetOrders);
            }
            currentTargetRatio = newTargetRatio;

            Order storage currentOrder  = orders[ upperSwap.token ] [ lowerSwap.token ][ currentTargetRatio ];
            
            require(currentOrder.inputSwap.token == outputSwap.token ,"Output swap address must match target orders");
            
            fillOrder(inputSwap, currentOrder, currentTargetRatio, direction, upperSwap.token, lowerSwap.token); 

        }

        //create order and stake leftover amount
        if(inputSwap.amount != 0){
            //stake to ecosystem if it's valid
            isEcosystem = IVersion( inputSwap.token ).isEcosystem();
            if ( isEcosystem ){
                IERC20(inputSwap.token).transferFrom(msgSender(), address(this), inputSwap.amount);
                IStake( inputSwap.token ).stake( msgSender(), inputSwap.amount, IStake.StakeTier.Continious , _stakeId );
            }
            orders[ upperSwap.token ][ lowerSwap.token ][ scaledRatio ] = Order(_stakeId, msgSender(), outputSwap.token, inputSwap);
        } 
        emit SwapOrderSubmitted(msgSender(), inputSwap.token, outputSwap.token, inputSwap.amount);
    }

    /**
        Need to know which ratio we're looking at, so need to choose a token to be numerator, 
        and the other denominator. Numerator is the largest valued token address. 
     */
    function swapOrdered(Swap memory swap1, Swap memory swap2) private returns ( Swap memory ,Swap memory, Direction){
        return swap1.token > swap2.token ? (swap1, swap2, Direction.Down) : (swap2, swap1, Direction.Up);
    }

    function ratioInvert(uint256 ratio) private pure returns (uint256 ratio_){
        ratio_ =  PRECISION / ratio;
    }

    /**
     * 
     * @param _inputSwap The caller's currency intended to be swapped for the outputSwap's currency
     * @param _currentOrder current order attempting to be filled
     * @param _currentOrderRatio the ratio the input token and output token will be swapped for the current order
     * @param _direction orientation of
     * @param upperAddress higher valued address with respect to it's counterpart token, removing the necessecity for saving order information twice
     * @param lowerAddress  lower valued address with respect to upper address
     */
    function fillOrder(Swap memory _inputSwap, Order memory _currentOrder, uint256 _currentOrderRatio, Direction _direction, address upperAddress, address lowerAddress) internal {
        //convert inputamount to output amount
        //need to find if input is upper or lower 
        // need to assert ratio corresponds to proper input token giving the corresponding output token in accordance with input/output swaps 
        uint256 orientedRatio = _direction == Direction.Down ? _currentOrderRatio : PRECISION / _currentOrderRatio;
        uint256 totalOutputAvailable = orientedRatio * _inputSwap.amount;
        uint256 outputAmountConsumed;
        if ( totalOutputAvailable < _currentOrder.inputSwap.amount ) {
            outputAmountConsumed = _currentOrder.inputSwap.amount - totalOutputAvailable;
            //fully complete order of input
            _inputSwap.amount = 0;
            

            emit Fill(msgSender(), _currentOrder.marketMaker, _currentOrderRatio, totalOutputAvailable, OrderFill.Partial);
        }
        else if (totalOutputAvailable >= _currentOrder.inputSwap.amount){
            outputAmountConsumed = totalOutputAvailable;
            //fully complete order of input
            uint256 consumedInputAmount =  ratioInvert( orientedRatio ) * ( totalOutputAvailable - _currentOrder.inputSwap.amount );
            _inputSwap.amount -= (consumedInputAmount);
            

            emit Fill(msgSender(), _currentOrder.marketMaker, _currentOrderRatio, totalOutputAvailable, OrderFill.Full );
            //fully complete order of input
            //fully complete current order and update amount. 
            //transfer to and from
        }
        //partially complete current order and update amount. 
            orders[upperAddress][ lowerAddress][_currentOrderRatio].inputSwap.amount -= outputAmountConsumed;
            //transfer from inputer
            IERC20(_inputSwap.token).transferFrom(msgSender(), _currentOrder.marketMaker, _inputSwap.amount);
            //tranfser from outputer
            IERC20(_currentOrder.inputSwap.token).transferFrom(address(this), msgSender(), totalOutputAvailable);
    }

    function cancelSwapOrder(uint256 ratio, address token1, address token2) external {
        (address upperToken, address lowerToken) = token1 > token2 ? (token1, token2) : (token2, token1);
        Order storage orders = orders[ upperToken ][ lowerToken ][ ratio ];

        require(orders.marketMaker == msgSender(), "Must use the account that initiated the swap order.");
        //zero swap entry
        address _tokenAddress = orders.inputSwap.token;
        uint256 _amount = orders.inputSwap.amount;
        uint256 _stakeId = orders.stakeId;
        bool _isEcosystem = IVersion(_tokenAddress).isEcosystem();

        uint256 _newAmount;
        if( _isEcosystem) { 
            _newAmount = IStake(_tokenAddress).unstake(msgSender(), _amount, _stakeId); 
        }
        else{
            _newAmount = _amount;
            IERC20(_tokenAddress).transfer(msgSender(), _newAmount);
        }
        emit SwapCancelled(msgSender(), ratio, _newAmount);
    }
}

//what does amount mean? More efficient if we say amount of upper token

/**
    preciseRatioAmount = upperToken * Precision / lowerToken
    
    What we want is a fixed ratio type like above, well defined. 

    Now we have inputSwap and targetSwaps. 

    We want to eat orders, how to we eat them? Well first we need to find out, 
    at the given targetSwap ratio, how much inputAmount corresponds to how much outputAmount.

 */