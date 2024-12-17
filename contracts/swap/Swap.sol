pragma solidity ^0.8.9;

import {IERC20} from "../facets/Tokens/ERC20/interfaces/IERC20.sol";
import { IStake } from "../facets/Stake/IStake.sol";
import { IVersion } from "./interfaces/IVersion.sol";
import { IPOCreate } from "./IPO.sol";  

import { PRBMathUD60x18 } from "./UD60x18.sol";

import "hardhat/console.sol";

/**
We want to allow for IPO purchasing and Internal Swapping 
(as opposed to swapping with other platforms).

 */
 //tokens can be simply ordered, so highest value will be numerator for the ratio, lowest is denominator
contract MassDXSwap is IPOCreate{
    using PRBMathUD60x18 for uint256;
    /**
        Sell a given token of type A for a given token of type B from 
        their respective ecosystems. 
      */
      
      struct Swap{  
        address token;
        bool isEther;
        uint256 amount;
      }
 
      enum Direction {UpperToLower, LowerToUpper}
      enum OrderFill {Partial, Full}

      // note: the order swaps input/output so that it matches the reference frame of a new swapper. 
      // hence outputSwap in this struct is really the inputSwap of the user that created the order.
      // But since the logic is primarily concerned with the current swapper, we keep naming convention
      // in line with their point of view. 
      struct Order{
        uint256 stakeId;
        address marketMaker;
        Swap inputSwap;
        Swap outputSwap; // the currency a new swap order will expect to receive
      }
      
   
        //upperAddress, lowerAddress, ratio
      mapping ( address => mapping(address => mapping( uint256 => Order ) ) )  orders;

      error MalOrderedArray(Direction direction, uint256[] targetOrders);
      
      event Fill(address inputSwap, address outputSwap, uint256 ratio, uint256 outputAmount, OrderFill orderFillType);
      event SwapOrderSubmitted(address swapIntiaitor, Swap inputSwapToken, Swap outputSwapToken, uint256 scaledRatio);
      event SwapCancelled(address marketMaker, uint256 ratio, uint256 amount);

      error InputSwapError(address inputSwapAddress, bool isInputSwapEther);
      error OutputSwapError(address outputSwapAddress, bool isOutputSwapEther);
      
    
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
    function swap(Swap memory inputSwap, Swap memory outputSwap, uint256[] memory targetOrders, uint256 _stakeId, bool isOrder) payable external {
         
        //convert to UD60x.18
        inputSwap.amount = inputSwap.amount.scale();
        outputSwap.amount = outputSwap.amount.scale();


        // swap requirements and conditions
        require(inputSwap.token != outputSwap.token , "Can't swap into the same ERC20 token");
        require(inputSwap.amount.mul( outputSwap.amount ) != 0 ,"Must have non-zero swap amounts.");
        require( ! ( inputSwap.isEther &&  outputSwap.isEther ),
                 "Both currencies can't be ether.");

        //Non-ether swap type can't have zero address 
        if( inputSwap.token == address(0) && !inputSwap.isEther ){
            revert InputSwapError(inputSwap.token, inputSwap.isEther);
        }
        if( outputSwap.token == address(0) && !outputSwap.isEther ){
            revert OutputSwapError(outputSwap.token, outputSwap.isEther);
        }

        //If one currency is ether, assign it the zero address for consistent ordering purposes
        if( inputSwap.isEther ){
            inputSwap.token = address(0);
            require( inputSwap.amount == msg.value.scale(),"Input swap amount must match ether received.");
        }
        else if( outputSwap.isEther ){
            outputSwap.token = address(0);
        }


        //set a direction such that increasing/decreasing ratios are expected for target orders
        (Swap memory upperSwap, Swap memory lowerSwap, Direction direction) = swapOrdered(inputSwap, outputSwap);
       
        uint256 scaledRatio = upperSwap.amount.div(lowerSwap.amount);
        console.log(uint8(38));
        console.log(scaledRatio);
        //loop through target orders, already in decreasing/increasing order with respect to user's
        //input swap
        if(targetOrders.length != 0){
            // need to initialize a ratio just below or above the first order's ratio
            // UpperToLower <---> UpperToken Swapped for LowerToken ---> Ratio ⬇️
            // LowerToUpper <---> LowerToken Swapped for UpperToken ---> Ratio ⬆️
            
            uint256 currentTargetRatio =  direction == Direction.UpperToLower ? targetOrders[0] +  1 : ( targetOrders[0] - 1 ); 
            for( uint256 orderIndex; orderIndex < targetOrders.length ; orderIndex ++){
                if(inputSwap.amount == 0){
                    break;
                }
                uint256 newTargetRatio = targetOrders[ orderIndex ];
                //assert arrays are well ordered in the proper direction 
                if( direction == Direction.UpperToLower && currentTargetRatio <= newTargetRatio ){  
                    revert MalOrderedArray(direction, targetOrders);
                }
                else if ( direction == Direction.LowerToUpper && currentTargetRatio >= newTargetRatio){ 
                    revert MalOrderedArray(direction, targetOrders);
                }
                currentTargetRatio = newTargetRatio;

                Order storage currentOrder  = orders[ upperSwap.token ] [ lowerSwap.token ][ currentTargetRatio ];

                require(currentOrder.outputSwap.token == outputSwap.token ,"Output swap address must match target orders");
                
                fillOrder(inputSwap, currentOrder, currentTargetRatio, direction);  

            }
        }
        
        //create order and stake leftover amount
        if(inputSwap.amount != 0 && isOrder){
            try IStake( outputSwap.token ).stakeVirtual( msgSender(), outputSwap.amount.descale(), IStake.StakeTier.Continious , _stakeId ) {} catch( bytes memory ){}

            if( inputSwap.isEther ){
                require( msg.value.scale() == inputSwap.amount, "Ether sent must match the input swap amount.");
            }
            else{  
                IERC20(inputSwap.token).transferFrom(msgSender(), address(this), inputSwap.amount.descale());
            }

            orders[ upperSwap.token ][ lowerSwap.token ][ scaledRatio ] = Order(_stakeId, msgSender(), outputSwap, inputSwap);
        } 
        emit SwapOrderSubmitted(msgSender(), inputSwap, outputSwap, scaledRatio); 
    }

    /**
        Need to know which ratio we're looking at, so need to choose a token to be numerator, 
        and the other denominator. Numerator is the largest valued token address. 
     */
    function swapOrdered(Swap memory swap1, Swap memory swap2) private returns ( Swap memory ,Swap memory, Direction){
        return swap1.token > swap2.token ? (swap1, swap2, Direction.UpperToLower) : (swap2, swap1, Direction.LowerToUpper);
    }

  

    /**
     * 
     * @param _inputSwap The caller's currency intended to be swapped for the outputSwap's currency
     * @param _currentOrder current order attempting to be filled
     * @param _currentOrderRatio the ratio the input token and output token will be swapped for the current order
     * @param _direction orientation of
     */
    function fillOrder(Swap memory _inputSwap, Order memory _currentOrder, uint256 _currentOrderRatio, Direction _direction ) internal {
        //convert inputamount to output amount
        //need to find if input is upper or lower 
        // need to assert ratio corresponds to proper input token giving the corresponding output token in accordance with input/output swaps 
        //i.e. if the input token is lower address, then we must use inverse ratio to convert to upper address (output)
        uint256 orientedRatio = _direction == Direction.UpperToLower ? _currentOrderRatio : _currentOrderRatio.inv();
        uint256 totalOutputAvailable = orientedRatio.mul( _inputSwap.amount );
        
        address payable marketMaker = payable( _currentOrder.marketMaker );

        uint256 outputAmountConsumed;
        uint256 inputAmountConsumed; 
        //PARTIAL FILL
        if ( totalOutputAvailable < _currentOrder.outputSwap.amount ) {
            outputAmountConsumed =  totalOutputAvailable;
            inputAmountConsumed = _inputSwap.amount;

            //fully complete order of input
            _inputSwap.amount = 0;

            emit Fill( msgSender(), _currentOrder.marketMaker, _currentOrderRatio, totalOutputAvailable, OrderFill.Partial );
        }
        //TOTAL FILL
        else if ( totalOutputAvailable >= _currentOrder.outputSwap.amount ){
            outputAmountConsumed = _currentOrder.outputSwap.amount;
            //fully complete order of input
            inputAmountConsumed = orientedRatio.inv() .mul( _currentOrder.outputSwap.amount );
            
            _inputSwap.amount -= (inputAmountConsumed);  
            
            emit Fill( msgSender(), _currentOrder.marketMaker, _currentOrderRatio, totalOutputAvailable, OrderFill.Full );
        }
        //PAYOUTS 
            //SWAPPER TRANSFER
            if(_inputSwap.isEther){
                address payable ethHolder = payable( _currentOrder.marketMaker );

                //get fee
                (bool success, ) = ethHolder.call{value : inputAmountConsumed.descale() }("");
 
                require(success, "Must succesfully transfer ether to market maker.");     
            }
            else{
                IERC20(_inputSwap.token).transferFrom( msgSender(), marketMaker, inputAmountConsumed.descale() );
            }
            //SWAP ORDER TRANSFER
            if( _currentOrder.outputSwap.isEther ){ 
                address payable swapper = payable( msgSender() );

                uint256 transferedAmount;
                uint256 rebate;
                try IStake( _currentOrder.inputSwap.token ).getGasStakeFee()  returns ( uint24 feeScale, uint24 fee ){
                    console.log(fee);
                    console.log(feeScale);
                    rebate =  ( outputAmountConsumed * feeScale ) / fee;
                    transferedAmount = outputAmountConsumed - rebate; 
                } catch(bytes memory e){ 
                    transferedAmount = outputAmountConsumed; 
                } 
                //transfer to swapper
                ( bool successSwapperTransfer, ) = swapper.call{value : transferedAmount.descale() }("");
                require( successSwapperTransfer, "Ether must be succesfully transferred to the swapper.");
                //transfer rebate to market maker
                if ( rebate != 0 ){
                    ( bool successMarketMakerTransfer, ) = marketMaker.call{value : rebate.descale() }("");
                    require( successMarketMakerTransfer, "Rebate must succesfully transfer to the marketMaker");
                }
            }
            else{ 
                //initial unstake transfers from ecosystem stake address to holder (this contract)
                try IStake( _currentOrder.inputSwap.token ).unstakeVirtual( marketMaker, inputAmountConsumed.descale(), _currentOrder.stakeId ) {} catch(bytes memory e){}
                //transfer from holder to 
                IERC20( _currentOrder.outputSwap.token ).transferFrom( address(this), msgSender(), inputAmountConsumed.descale() ); 
            }
            _currentOrder.outputSwap.amount -= outputAmountConsumed; 
    } 

    function cancelSwapOrder(uint256 ratio, address token1, address token2) external {
        (address upperToken, address lowerToken) = token1 > token2 ? (token1, token2) : (token2, token1);
        Order storage orders = orders[ upperToken ][ lowerToken ][ ratio ];

        require(orders.marketMaker == msgSender(), "Must use the account that initiated the swap order.");
        //zero swap entry 
        address _tokenAddress = orders.outputSwap.token;
        uint256 _amount = orders.outputSwap.amount;
        bool _isEcosystem = IVersion(_tokenAddress).isEcosystem();

        uint256 _newAmount;
         
        if( _isEcosystem ) { 
            uint256 _stakeId = orders.stakeId;
            _newAmount = IStake(_tokenAddress).unstakeContract(msgSender(), _amount, _stakeId); 
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