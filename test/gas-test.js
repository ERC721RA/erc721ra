const { expect } = require("chai");
const { ethers } = require("hardhat");
const { BigNumber } = require("ethers");

const parseEther = ethers.utils.parseEther;

let RA_NFT, contract;
let owner, account02, account03;

const REFUND_TIME = 60 * 60 * 24; // 1 day
const MINT_PRICE = "0.1";

beforeEach(async () => {
  [owner, account02, account03] = await ethers.getSigners();

  RA_NFT = await ethers.getContractFactory("ERC721RA_NFT");
  contract = await RA_NFT.deploy(0);
  await contract.deployed();
});

describe("Gas Test", function () {
  it("Mint 1x ERC721RA ...", async function () {
    await contract.connect(account02).mint1x({ value: parseEther(MINT_PRICE) });
    await contract.connect(account02).mint1x({ value: parseEther(MINT_PRICE) });
    await contract.connect(account02).mint1x({ value: parseEther(MINT_PRICE) });
    await contract.connect(account02).mint1x({ value: parseEther(MINT_PRICE) });
    await contract.connect(account02).mint1x({ value: parseEther(MINT_PRICE) });
  });

  it("Mint 2x ERC721RA ...", async function () {
    await contract.connect(account02).mint2x({ value: parseEther(MINT_PRICE) });
    await contract.connect(account02).mint2x({ value: parseEther(MINT_PRICE) });
    await contract.connect(account02).mint2x({ value: parseEther(MINT_PRICE) });
    await contract.connect(account02).mint2x({ value: parseEther(MINT_PRICE) });
    await contract.connect(account02).mint2x({ value: parseEther(MINT_PRICE) });
  });

  it("Mint 3x ERC721RA ...", async function () {
    await contract.connect(account02).mint3x({ value: parseEther(MINT_PRICE) });
    await contract.connect(account02).mint3x({ value: parseEther(MINT_PRICE) });
    await contract.connect(account02).mint3x({ value: parseEther(MINT_PRICE) });
    await contract.connect(account02).mint3x({ value: parseEther(MINT_PRICE) });
    await contract.connect(account02).mint3x({ value: parseEther(MINT_PRICE) });
  });

  it("Mint 4x ERC721RA ...", async function () {
    await contract.connect(account02).mint4x({ value: parseEther(MINT_PRICE) });
    await contract.connect(account02).mint4x({ value: parseEther(MINT_PRICE) });
    await contract.connect(account02).mint4x({ value: parseEther(MINT_PRICE) });
    await contract.connect(account02).mint4x({ value: parseEther(MINT_PRICE) });
    await contract.connect(account02).mint4x({ value: parseEther(MINT_PRICE) });
  });

  it("Mint 5x ERC721RA ...", async function () {
    await contract.connect(account02).mint5x({ value: parseEther(MINT_PRICE) });
    await contract.connect(account02).mint5x({ value: parseEther(MINT_PRICE) });
    await contract.connect(account02).mint5x({ value: parseEther(MINT_PRICE) });
    await contract.connect(account02).mint5x({ value: parseEther(MINT_PRICE) });
    await contract.connect(account02).mint5x({ value: parseEther(MINT_PRICE) });
  });

  it("Mint 6x ERC721RA ...", async function () {
    await contract.connect(account02).mint6x({ value: parseEther(MINT_PRICE) });
    await contract.connect(account02).mint6x({ value: parseEther(MINT_PRICE) });
    await contract.connect(account02).mint6x({ value: parseEther(MINT_PRICE) });
    await contract.connect(account02).mint6x({ value: parseEther(MINT_PRICE) });
    await contract.connect(account02).mint6x({ value: parseEther(MINT_PRICE) });
  });

  it("Mint 7x ERC721RA ...", async function () {
    await contract.connect(account02).mint7x({ value: parseEther(MINT_PRICE) });
    await contract.connect(account02).mint7x({ value: parseEther(MINT_PRICE) });
    await contract.connect(account02).mint7x({ value: parseEther(MINT_PRICE) });
    await contract.connect(account02).mint7x({ value: parseEther(MINT_PRICE) });
    await contract.connect(account02).mint7x({ value: parseEther(MINT_PRICE) });
  });

  it("Mint 8x ERC721RA ...", async function () {
    await contract.connect(account02).mint8x({ value: parseEther(MINT_PRICE) });
    await contract.connect(account02).mint8x({ value: parseEther(MINT_PRICE) });
    await contract.connect(account02).mint8x({ value: parseEther(MINT_PRICE) });
    await contract.connect(account02).mint8x({ value: parseEther(MINT_PRICE) });
    await contract.connect(account02).mint8x({ value: parseEther(MINT_PRICE) });
  });

  it("Mint 9x ERC721RA ...", async function () {
    await contract.connect(account02).mint9x({ value: parseEther(MINT_PRICE) });
    await contract.connect(account02).mint9x({ value: parseEther(MINT_PRICE) });
    await contract.connect(account02).mint9x({ value: parseEther(MINT_PRICE) });
    await contract.connect(account02).mint9x({ value: parseEther(MINT_PRICE) });
    await contract.connect(account02).mint9x({ value: parseEther(MINT_PRICE) });
  });

  it("Mint 10x ERC721RA ...", async function () {
    await contract
      .connect(account02)
      .mint10x({ value: parseEther(MINT_PRICE) });
    await contract
      .connect(account02)
      .mint10x({ value: parseEther(MINT_PRICE) });
    await contract
      .connect(account02)
      .mint10x({ value: parseEther(MINT_PRICE) });
    await contract
      .connect(account02)
      .mint10x({ value: parseEther(MINT_PRICE) });
    await contract
      .connect(account02)
      .mint10x({ value: parseEther(MINT_PRICE) });
  });
});
