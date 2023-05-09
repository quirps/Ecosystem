
const chai = require('chai');
const { expect, assert } = chai;
const { ethers } = require('hardhat');
const { solidity } = require('ethereum-waffle');

chai.use(solidity);
const {
    getSelectors,
    FacetCutAction,
    removeSelectors,
    findAddressPositionInFacets
} = require('../scripts/libraries/diamond.js')

const { deployDiamond } = require('../scripts/deploy.js')
const { deployFacet } = require('../scripts/deployFacet.js')


const { ERC1155Config } = require("../scripts/utils/erc1155Saturate.js")
// Test Base functionality
//  - Swap Fungible Token User1 to User 2
//        assert balances User1, User2
//        assert over-drawn User1,User2
//  - Swap Owner approval
//        assert User1 to User2 balances
//  - Swap 


//Deploy diamond
//Deploy Erc1155
//Fund Users
//Deploy Operator Contract
const FUNGIBLE_TOKEN_ID = 0;
const TICKET_ID = 1;

describe("ERC1155 Base", async function () {
    let diamondAddress;
    let diamondCutFacet;
    let erc1155Facet;
    let erc1155TransferFacet;
    let user1, user2, user3;
    before(async function () {
        diamondAddress = await deployDiamond();
        [user1, user2, user3] = await ethers.getSigners()
        // balance of signer
        // const provider = ethers.provider;
        // const balance = await provider.getBalance(users[0].address);
        let ERC1155CallData = "0x"
        await deployFacet(["ERC1155"], diamondAddress, ethers.constants.AddressZero, ERC1155CallData);
        await deployFacet(["ERC1155Transfer"], diamondAddress, ethers.constants.AddressZero, ERC1155CallData);


        erc1155Facet = await ethers.getContractAt('IERC1155', diamondAddress)
        erc1155TransferFacet = await ethers.getContractAt('IERC1155Transfer', diamondAddress)

        await ERC1155Config(ethers.constants.AddressZero, erc1155Facet, erc1155TransferFacet)
    })
    describe("Minting , Burning, and fund distribution ", async function () {
        console.log("Minting, Burning...")
        it("ERC1155 mint 1 ticket", async function () {
            console.log("Mint1")
            let balance = await erc1155Facet.balanceOf(user1.address, 0)
            console.log(balance.toString())
            assert.equal(balance.toString(), `1000`);
            //xpect(balance.toString() == '1000')
        })

    })
    describe("Transfers", async function () {
        console.log("Minting, Burning...")
        it("Transfer Base Currency", async function () {
            let balance1;
            let balance2;
            await erc1155TransferFacet.safeTransferFrom(user1.address, user2.address, 0, 100, '0x')
            balance1 = await erc1155Facet.balanceOf(user1.address, 0);
            balance2 = await erc1155Facet.balanceOf(user2.address, 0);


            assert.equal(balance1.toString(), `900`);
            assert.equal(balance2.toString(), `1100`);
            //xpect(balance.toString() == '1000')
        })
        it("Transfer Ticket", async function () {
            let balance2;
            let balance3;
            await erc1155TransferFacet.connect(user2).safeTransferFrom(
                user2.address, user3.address, 3, 1, "0x"
            )
            balance2 = await erc1155Facet.balanceOf(user2.address, 3);
            balance3 = await erc1155Facet.balanceOf(user3.address, 3);


            assert.equal(balance2.toString(), `4`);
            assert.equal(balance3.toString(), `6`);
        })

        it("Transfer Ticket Approval", async function () {
            let balance2;
            let balance3;
            let mediatorContract;

            let _mediatorContract = await ethers.getContractFactory("TestERC1155Operator")
            mediatorContract = await _mediatorContract.deploy(diamondAddress)
            //deploy third party contract which mediates transfers
            //transfer 

            //fail
            await expect(mediatorContract.connect(user3).safeTransferFrom(
                user3.address, user2.address, 3, 1, "0x"
            )).revertedWith('ERC1155: caller is not token owner or approved')

            //success
            await erc1155TransferFacet.connect(user3).setApprovalForAll(
                mediatorContract.address, true
            )
            await mediatorContract.connect(user3).safeTransferFrom(
                user3.address, user2.address, 3, 1, "0x"
            )
            balance2 = await erc1155Facet.balanceOf(user2.address, 3);
            balance3 = await erc1155Facet.balanceOf(user3.address, 3);


            assert.equal(balance2.toString(), `5`);
            assert.equal(balance3.toString(), `5`);
        })
    })

    describe("Mint/Burn", async function(){
        it("Mint and Burn", async function(){
            let balance1;
            let balance2;
            await erc1155Facet.mint(user2.address,10,5,'0x')

            balance1 = await erc1155Facet.balanceOf(user2.address,10)
            assert.equal( balance1.toString() , '5');

            await erc1155Facet.burn(user2.address,10,3);
            balance2 = await erc1155Facet.balanceOf(user2.address,10)
            assert.equal( balance2.toString() , '2');
        })

        it("Mint and Burn Batch", async function(){
            await erc1155Facet.mintBatch(user2.address,[15,16],[5,15],'0x')
            const [mintBalance1,mintBalance2] = await erc1155Facet.balanceOfBatch([user2.address,user2.address],
                [15,16] )

            assert.equal( mintBalance1.toString() , '5');
            assert.equal( mintBalance2.toString() , '15');

            await erc1155Facet.burnBatch(user2.address,[15,16],[3,2]);
            const [burnBalance1,burnBalance2] = await erc1155Facet.balanceOfBatch([user2.address,user2.address],
                [15,16] )

            assert.equal( burnBalance1.toString() , '2');
            assert.equal( burnBalance2.toString() , '13');
        })       
    })

    


})
