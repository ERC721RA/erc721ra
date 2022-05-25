const { ethers } = require("hardhat");

const parseEther = ethers.utils.parseEther;

let RA_NFT, contract;
let owner;

const MINT_PRICE = "0.1";

beforeEach(async () => {
  [owner] = await ethers.getSigners();

  RA_NFT = await ethers.getContractFactory("ERC721RA_NFT");
  contract = await RA_NFT.deploy(0);
  await contract.deployed();
});

describe("GAS_TEST", function () {
  it("Mint 1x ERC721RA ...", async function () {
    await contract.connect(owner).mint1x({ value: parseEther(MINT_PRICE) });
    await contract.connect(owner).mint1x({ value: parseEther(MINT_PRICE) });
    await contract.connect(owner).mint1x({ value: parseEther(MINT_PRICE) });
    await contract.connect(owner).mint1x({ value: parseEther(MINT_PRICE) });
    await contract.connect(owner).mint1x({ value: parseEther(MINT_PRICE) });
  });

  it("Mint 2x ERC721RA ...", async function () {
    await contract.connect(owner).mint2x({ value: parseEther(MINT_PRICE) });
    await contract.connect(owner).mint2x({ value: parseEther(MINT_PRICE) });
    await contract.connect(owner).mint2x({ value: parseEther(MINT_PRICE) });
    await contract.connect(owner).mint2x({ value: parseEther(MINT_PRICE) });
    await contract.connect(owner).mint2x({ value: parseEther(MINT_PRICE) });
  });

  it("Mint 3x ERC721RA ...", async function () {
    await contract.connect(owner).mint3x({ value: parseEther(MINT_PRICE) });
    await contract.connect(owner).mint3x({ value: parseEther(MINT_PRICE) });
    await contract.connect(owner).mint3x({ value: parseEther(MINT_PRICE) });
    await contract.connect(owner).mint3x({ value: parseEther(MINT_PRICE) });
    await contract.connect(owner).mint3x({ value: parseEther(MINT_PRICE) });
  });

  it("Mint 4x ERC721RA ...", async function () {
    await contract.connect(owner).mint4x({ value: parseEther(MINT_PRICE) });
    await contract.connect(owner).mint4x({ value: parseEther(MINT_PRICE) });
    await contract.connect(owner).mint4x({ value: parseEther(MINT_PRICE) });
    await contract.connect(owner).mint4x({ value: parseEther(MINT_PRICE) });
    await contract.connect(owner).mint4x({ value: parseEther(MINT_PRICE) });
  });

  it("Mint 5x ERC721RA ...", async function () {
    await contract.connect(owner).mint5x({ value: parseEther(MINT_PRICE) });
    await contract.connect(owner).mint5x({ value: parseEther(MINT_PRICE) });
    await contract.connect(owner).mint5x({ value: parseEther(MINT_PRICE) });
    await contract.connect(owner).mint5x({ value: parseEther(MINT_PRICE) });
    await contract.connect(owner).mint5x({ value: parseEther(MINT_PRICE) });
  });

  it("Mint 6x ERC721RA ...", async function () {
    await contract.connect(owner).mint6x({ value: parseEther(MINT_PRICE) });
    await contract.connect(owner).mint6x({ value: parseEther(MINT_PRICE) });
    await contract.connect(owner).mint6x({ value: parseEther(MINT_PRICE) });
    await contract.connect(owner).mint6x({ value: parseEther(MINT_PRICE) });
    await contract.connect(owner).mint6x({ value: parseEther(MINT_PRICE) });
  });

  it("Mint 7x ERC721RA ...", async function () {
    await contract.connect(owner).mint7x({ value: parseEther(MINT_PRICE) });
    await contract.connect(owner).mint7x({ value: parseEther(MINT_PRICE) });
    await contract.connect(owner).mint7x({ value: parseEther(MINT_PRICE) });
    await contract.connect(owner).mint7x({ value: parseEther(MINT_PRICE) });
    await contract.connect(owner).mint7x({ value: parseEther(MINT_PRICE) });
  });

  it("Mint 8x ERC721RA ...", async function () {
    await contract.connect(owner).mint8x({ value: parseEther(MINT_PRICE) });
    await contract.connect(owner).mint8x({ value: parseEther(MINT_PRICE) });
    await contract.connect(owner).mint8x({ value: parseEther(MINT_PRICE) });
    await contract.connect(owner).mint8x({ value: parseEther(MINT_PRICE) });
    await contract.connect(owner).mint8x({ value: parseEther(MINT_PRICE) });
  });

  it("Mint 9x ERC721RA ...", async function () {
    await contract.connect(owner).mint9x({ value: parseEther(MINT_PRICE) });
    await contract.connect(owner).mint9x({ value: parseEther(MINT_PRICE) });
    await contract.connect(owner).mint9x({ value: parseEther(MINT_PRICE) });
    await contract.connect(owner).mint9x({ value: parseEther(MINT_PRICE) });
    await contract.connect(owner).mint9x({ value: parseEther(MINT_PRICE) });
  });

  it("Mint 10x ERC721RA ...", async function () {
    await contract.connect(owner).mint10x({ value: parseEther(MINT_PRICE) });
    await contract.connect(owner).mint10x({ value: parseEther(MINT_PRICE) });
    await contract.connect(owner).mint10x({ value: parseEther(MINT_PRICE) });
    await contract.connect(owner).mint10x({ value: parseEther(MINT_PRICE) });
    await contract.connect(owner).mint10x({ value: parseEther(MINT_PRICE) });
  });
});
