const { expect } = require('chai');
const { ethers } = require('hardhat');

describe('ERC1155', function () {
  let erc1155;

  beforeEach(async function () {
    const ERC1155 = await ethers.getContractFactory('ERC1155');
    erc1155 = await ERC1155.deploy();
    await erc1155.deployed();
  });

  it('should return the correct name and symbol', async function () {
    expect(await erc1155.name()).to.equal('ERC1155');
    expect(await erc1155.symbol()).to.equal('E1155');
  });

  it('should mint a new token', async function () {
    const tokenId = 1;
    const initialSupply = 10;
    const metadataURI = 'https://example.com/token/1';
    const recipient = '0x0000000000000000000000000000000000000000';

    await erc1155.mint(tokenId, initialSupply, metadataURI);
    const balance = await erc1155.balanceOf(recipient, tokenId);

    expect(balance).to.equal(initialSupply);
  });

  it('should transfer a token', async function () {
    const tokenId = 1;
    const initialSupply = 10;
    const metadataURI = 'https://example.com/token/1';
    const sender = '0x0000000000000000000000000000000000000000';
    const recipient = '0x1111111111111111111111111111111111111111';

    await erc1155.mint(tokenId, initialSupply, metadataURI);
    await erc1155.safeTransferFrom(sender, recipient, tokenId, 1, []);

    const senderBalance = await erc1155.balanceOf(sender, tokenId);
    const recipientBalance = await erc1155.balanceOf(recipient, tokenId);

    expect(senderBalance).to.equal(initialSupply - 1);
    expect(recipientBalance).to.equal(1);
  });

  it('should batch transfer tokens', async function () {
    const tokenIds = [1, 2, 3];
    const initialSupplies = [10, 20, 30];
    const metadataURIs = [
      'https://example.com/token/1',
      'https://example.com/token/2',
      'https://example.com/token/3'
    ];
    const sender = '0x0000000000000000000000000000000000000000';
    const recipient = '0x1111111111111111111111111111111111111111';

    for (let i = 0; i < tokenIds.length; i++) {
      await erc1155.mint(tokenIds[i], initialSupplies[i], metadataURIs[i]);
    }

    await erc1155.safeBatchTransferFrom(
      sender,
      recipient,
      tokenIds,
      [1, 2, 3],
      []
    );

    for (let i = 0; i < tokenIds.length; i++) {
      const senderBalance = await erc1155.balanceOf(sender, tokenIds[i]);
      const recipientBalance = await erc1155.balanceOf(recipient, tokenIds[i]);

      expect(senderBalance).to.equal(initialSupplies[i] - i);
      expect(recipientBalance).to.equal(i + 1);
    }
  });
});
