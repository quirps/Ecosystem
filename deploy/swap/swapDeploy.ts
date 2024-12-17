const { ethers } = require("hardhat");
import type { Signer } from "ethers";
//import type {Swap, Order } from "../../types/ethers-contracts/swap/Swap"
import type { MassDXSwap } from "../../types/ethers-contracts/swap/Swap/MassDXSwap";

const PRECISION = BigInt(10) ** BigInt(18);

interface Stake {
  stakeId: number;
  isStaked: boolean;
}

interface SwapOrder {
  inputSwap: MassDXSwap.SwapStruct;
  outputSwap: MassDXSwap.SwapStruct;
  targetOrders: number[];
  stakeId: number;
  isOrder: boolean;
}

export async function swapDeploy(): Promise<any> {
  const SwapDeploy = await ethers.getContractFactory("MassDXSwap");
  const swapDeploy = await SwapDeploy.deploy();
  return swapDeploy;
  console.log("Swap and IPO deployed");
}

//generate swap orders for a particular ecosystem for a set of users
/**
 * want to create a set of swaps within a given range. an ecosystem
 * token and ether
 */
// Generate unique stake IDs
let uniqueStakeId = 1;

// Function to create swap orders
export async function generateSwapOrders(
  signers: Signer[],
  token1: string,
  token2: string,
  swapContract: any
) {
  const swapOrders1: any[] = [];
  const swapOrders2: any[] = [];
  const txs: any[] = [];
  const variance = 5; // Variance percentage to ensure input and output amounts are close but not equal

  // Helper to calculate random variance
  const applyVariance = (amount: number): number => {
    const factor = 1 + (Math.random() * 2 - 1) * (variance / 100);
    return Math.round(amount * factor);
  };
  const orders: any[] = [];
  // Generate orders for each signer
  for (const signer of signers) {
    const _swapContract = swapContract.connect(signer);
    // Randomize amounts for swaps
    const inputSwapAmount = Math.floor(Math.random() * 1000) + 1; // Random amount between 1 and 1000
    let outputSwapAmount = applyVariance(inputSwapAmount);
    while (outputSwapAmount === inputSwapAmount) {
      outputSwapAmount = applyVariance(inputSwapAmount);
    }

    // Create unique stake if necessary
    const stakeId = uniqueStakeId++; // 50% chance to create a stake

    // Add swap order from token1 to token2
    const _swapOrder1 = [
      {
        token: token1,
        isEther: token1 === ethers.constants.AddressZero,
        amount: Math.floor(inputSwapAmount),
      },
      {
        token: token2,
        isEther: token2 === ethers.constants.AddressZero,
        amount: Math.floor(outputSwapAmount),
      },
      [],
      stakeId,
      true,
    ];
    swapOrders1.push(_swapOrder1);
    txs.push(_swapContract.swap(..._swapOrder1));
    // Add swap order from token2 to token1 with a non-overlapping ratio

    const _swapOrder2 = [
      {
        token: token2,
        isEther: token2 === ethers.constants.AddressZero,
        amount: Math.floor(outputSwapAmount * 0.9),
      },
      {
        token: token1,
        isEther: token1 === ethers.constants.AddressZero,
        amount: Math.floor(inputSwapAmount * 1.1),
      },
      [],
      stakeId,
      true,
    ];
    console.log(_swapOrder2);
    txs.push(_swapContract.swap(..._swapOrder2));

    swapOrders2.push(_swapOrder2);


  }

  //transact

  await Promise.all(txs);
  console.log("Completed all swap orders!");
  return [swapOrders1, swapOrders2];
}

async function main() {
  // Example usage
  const signers: Signer[] = await ethers.getSigners(); // Replace with actual signer objects
  const token1 = "0xTokenAddress1"; // Replace with actual token address
  const token2 = "0xTokenAddress2"; // Replace with actual token address
  const swapContract = "0xSwapContractAddress"; // Replace with actual contract address

  const swapOrders = generateSwapOrders(signers, token1, token2, swapContract);
  console.log(swapOrders);
}

//take an array of swap orders and a given signer and consume
//full and partial orders
export async function consumeSwapOrders(
  signer: Signer,
  swapOrder: any,
  swapContract: any
) {
  console.log(`This is the signer - ${await signer.getAddress()} `);
  const [swapOrderUpper, swapOrderLower] = addressOrder(swapOrder);
  const ratio: BigInt = calculateTargetRatioSwap(swapOrderUpper, swapOrderLower);

  console.log(swapOrderUpper.amount);
  console.log(swapOrderLower.amount);
  console.log(ratio.toString());
  const _swapContract = swapContract.connect(signer);
  _swapContract.on(
    "Fill",
    (
      sender: string,
      orderRatio: BigInt,
      orderAmount: BigInt,
      totalOutputAvailable: BigInt,
      fillType: any
    ) => {
      console.log("Order Filled");
      console.log(sender);
      console.log(orderRatio);
      console.log(orderAmount);
      console.log(totalOutputAvailable);
      console.log(fillType);
    }
  );
  _swapContract.on(
    "SwapOrderSubmitted",
    (
      sender: string,
      inputToken: string,
      outputToken: string,
      inputAmount: BigInt
    ) => {
      console.log("SwapOrderSubmitted");
      console.log(sender);
      console.log(inputToken);
      console.log(outputToken);
      console.log(inputAmount);
    }
  );
  console.log(await signer.getAddress());
  const tx = await _swapContract.swap(
    swapOrder[1],
    swapOrder[0],
    [ratio],
    0,
    false
  );
  await tx.wait();
  console.log("Swap Complete");

  //need to get orientation of swap orders, seperate them into two categories, ordered.
  // we will change the format and export that from swap generate
  // then we test the consumption full/partial (for completion)
  // then we will modify the previous setup to include ether swaps
  // once the ether swaps have been done succesfully, do a quick test to assrt working,
  // and start writing relay

  // eventually we'll get a base deploy state in which we can write tests from
  //
}

function addressOrder(swapOrder: any): [any, any] {
  // Compare the values and return the smaller and larger address
  if (BigInt(swapOrder[1].token) < BigInt(swapOrder[0].token)) {
    return [swapOrder[0], swapOrder[1]]; // [lower address, higher address]
  } else {
    return [swapOrder[1], swapOrder[0]]; // [lower address, higher address]
  }
}

function calculateTargetRatioSwap(swapOrderUpper: any, swapOrderLower: any) {
  return (
    ( BigInt(swapOrderUpper.amount) * PRECISION ) / BigInt( swapOrderLower.amount )
  );
}

function calculateTargetRatio( amount1: any, amount2: any) {
  return (
    ( BigInt( amount1 ) * PRECISION ) / BigInt( amount2 )
  );
}
function toUD60x18(value: any) {
  return value * PRECISION;
}


export async function ethSwapTest (swapContract :any , token1 :string ) {

  const ethAmount = BigInt( 1000 ) * BigInt( ethers.constants.WeiPerEther );
  const signers : Signer[] = await ethers.getSigners()
  const [ signer1, signer2 ] = signers.slice(8,10)
  
  const _swapSigner1 = swapContract.connect( signer1 )
  const ethSwapOrder = [
      {
        token: ethers.constants.AddressZero,
        isEther: true,
        amount: ethAmount,
      },
      {
        token: token1,
        isEther: false,
        amount: BigInt( 1000 ) * BigInt( ethers.constants.WeiPerEther ),
      },
      [],
      3940940,
      true,
    ];  
    console.log(ethers.constants.AddressZero)
    console.log(token1)

    console.log("Create swap order")
    await _swapSigner1.swap(...ethSwapOrder, { value:ethAmount } );
  
   
  
    const _swapSigner2 = swapContract.connect ( signers[9] );
    
    const ratio = calculateTargetRatio( BigInt( 1000 ) * BigInt( ethers.constants.WeiPerEther ), ethAmount )
    const ethSwapOrder2 = [
      {
        token: token1,
        isEther: false,
        amount: BigInt( 1000 ) * BigInt( ethers.constants.WeiPerEther ),
      },
      {
        token: ethers.constants.AddressZero,
        isEther: true,
        amount: ethAmount,
      },
      [ ratio ],
      3940940123,
      true,
    ];  
    console.log("Consume Swap Order")
    await _swapSigner2.swap(...ethSwapOrder2 );
    
    
  }
