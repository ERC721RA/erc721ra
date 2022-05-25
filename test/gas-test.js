const { ethers } = require("hardhat");

const parseEther = ethers.utils.parseEther;

let RA_NFT, contract;
let owner;

beforeEach(async () => {
  [owner] = await ethers.getSigners();

  RA_NFT = await ethers.getContractFactory("ERC721RA_NFT");
  contract = await RA_NFT.deploy(0, parseEther("0.01"));
  await contract.deployed();
});

describe("GAS_TEST", function () {
  it("Mint 1x ERC721RA ...", async function () {
    await contract.connect(owner).mint1x({ value: parseEther("0.01") });
    await contract.connect(owner).mint1x({ value: parseEther("0.01") });
    await contract.connect(owner).mint1x({ value: parseEther("0.01") });
    await contract.connect(owner).mint1x({ value: parseEther("0.01") });
    await contract.connect(owner).mint1x({ value: parseEther("0.01") });
  });

  it("Mint 2x ERC721RA ...", async function () {
    await contract.connect(owner).mint2x({ value: parseEther("0.02") });
    await contract.connect(owner).mint2x({ value: parseEther("0.02") });
    await contract.connect(owner).mint2x({ value: parseEther("0.02") });
    await contract.connect(owner).mint2x({ value: parseEther("0.02") });
    await contract.connect(owner).mint2x({ value: parseEther("0.02") });
  });

  it("Mint 3x ERC721RA ...", async function () {
    await contract.connect(owner).mint3x({ value: parseEther("0.03") });
    await contract.connect(owner).mint3x({ value: parseEther("0.03") });
    await contract.connect(owner).mint3x({ value: parseEther("0.03") });
    await contract.connect(owner).mint3x({ value: parseEther("0.03") });
    await contract.connect(owner).mint3x({ value: parseEther("0.03") });
  });

  it("Mint 4x ERC721RA ...", async function () {
    await contract.connect(owner).mint4x({ value: parseEther("0.04") });
    await contract.connect(owner).mint4x({ value: parseEther("0.04") });
    await contract.connect(owner).mint4x({ value: parseEther("0.04") });
    await contract.connect(owner).mint4x({ value: parseEther("0.04") });
    await contract.connect(owner).mint4x({ value: parseEther("0.04") });
  });

  it("Mint 5x ERC721RA ...", async function () {
    await contract.connect(owner).mint5x({ value: parseEther("0.05") });
    await contract.connect(owner).mint5x({ value: parseEther("0.05") });
    await contract.connect(owner).mint5x({ value: parseEther("0.05") });
    await contract.connect(owner).mint5x({ value: parseEther("0.05") });
    await contract.connect(owner).mint5x({ value: parseEther("0.05") });
  });

  it("Mint 6x ERC721RA ...", async function () {
    await contract.connect(owner).mint6x({ value: parseEther("0.06") });
    await contract.connect(owner).mint6x({ value: parseEther("0.06") });
    await contract.connect(owner).mint6x({ value: parseEther("0.06") });
    await contract.connect(owner).mint6x({ value: parseEther("0.06") });
    await contract.connect(owner).mint6x({ value: parseEther("0.06") });
  });

  it("Mint 7x ERC721RA ...", async function () {
    await contract.connect(owner).mint7x({ value: parseEther("0.07") });
    await contract.connect(owner).mint7x({ value: parseEther("0.07") });
    await contract.connect(owner).mint7x({ value: parseEther("0.07") });
    await contract.connect(owner).mint7x({ value: parseEther("0.07") });
    await contract.connect(owner).mint7x({ value: parseEther("0.07") });
  });

  it("Mint 8x ERC721RA ...", async function () {
    await contract.connect(owner).mint8x({ value: parseEther("0.08") });
    await contract.connect(owner).mint8x({ value: parseEther("0.08") });
    await contract.connect(owner).mint8x({ value: parseEther("0.08") });
    await contract.connect(owner).mint8x({ value: parseEther("0.08") });
    await contract.connect(owner).mint8x({ value: parseEther("0.08") });
  });

  it("Mint 9x ERC721RA ...", async function () {
    await contract.connect(owner).mint9x({ value: parseEther("0.09") });
    await contract.connect(owner).mint9x({ value: parseEther("0.09") });
    await contract.connect(owner).mint9x({ value: parseEther("0.09") });
    await contract.connect(owner).mint9x({ value: parseEther("0.09") });
    await contract.connect(owner).mint9x({ value: parseEther("0.09") });
  });

  it("Mint 10x ERC721RA ...", async function () {
    await contract.connect(owner).mint10x({ value: parseEther("0.10") });
    await contract.connect(owner).mint10x({ value: parseEther("0.10") });
    await contract.connect(owner).mint10x({ value: parseEther("0.10") });
    await contract.connect(owner).mint10x({ value: parseEther("0.10") });
    await contract.connect(owner).mint10x({ value: parseEther("0.10") });
  });
});
