const { expect } = require("chai");
const { ethers } = require("hardhat");
const { BigNumber } = require("ethers");

const parseEther = ethers.utils.parseEther;

let RA_NFT;
let owner, account02, account03;

const REFUND_TIME_ZERO = 0;
const REFUND_TIME = 60 * 60 * 24; // 1 day

const MINT_PRICE_ZERO = 0;
const MINT_PRICE = "0.1";

beforeEach(async () => {
  [owner, account02, account03] = await ethers.getSigners();
  // Set the initial ETH balance
  await ethers.provider.send("hardhat_setBalance", [
    owner.address,
    parseEther("1").toHexString().replace("0x0", "0x"), // 1 ether
  ]);

  // Set the initial ETH balance
  await ethers.provider.send("hardhat_setBalance", [
    account02.address,
    parseEther("1").toHexString().replace("0x0", "0x"), // 1 ether
  ]);

  // Set the initial ETH balance
  await ethers.provider.send("hardhat_setBalance", [
    account03.address,
    parseEther("1").toHexString().replace("0x0", "0x"), // 1 ether
  ]);

  RA_NFT = await ethers.getContractFactory("ERC721RA_NFT");
});

describe("INITIAL_TEST", function () {
  it("Should store return data correctly ...", async function () {
    const deployTimestamp = (await ethers.provider.getBlock("latest"))
      .timestamp;
    const contract = await RA_NFT.deploy(REFUND_TIME + deployTimestamp);
    await contract.deployed();

    const refundEndtime = await contract.refundEndTime();
    const isRefundActive = await contract.isRefundActive();
    const returnAddress = await contract.returnAddress();

    expect(refundEndtime).to.eq(REFUND_TIME + deployTimestamp);
    expect(isRefundActive).to.eq(true);
    expect(returnAddress).to.eq(owner.address);
  });

  it("Should store correct price, when mint multiple token ...", async function () {
    const deployTimestamp = (await ethers.provider.getBlock("latest"))
      .timestamp;
    const contract = await RA_NFT.deploy(REFUND_TIME + deployTimestamp);
    await contract.deployed();

    // Mint a token from account02
    let tx = await contract
      .connect(account02)
      .mint(1, { value: parseEther(MINT_PRICE) });

    let receipt = await tx.wait();
    const tokenId01 = receipt.logs[0].topics[3];

    // Check price paid stored in contract
    const pricePaid01 = await contract.pricePaid(tokenId01);
    let priceExpected = BigNumber.from(parseEther(MINT_PRICE));
    expect(pricePaid01).to.eq(priceExpected);

    // Mint 9 tokens from account02
    tx = await contract
      .connect(account02)
      .mint(9, { value: parseEther(MINT_PRICE) });

    receipt = await tx.wait();
    const tokenId02 = receipt.logs[0].topics[3];
    const tokenId03 = receipt.logs[1].topics[3]; // get tokenId from event logs

    // Check price paid stored in contract
    const pricePaid02 = await contract.pricePaid(tokenId02);
    const pricePaid03 = await contract.pricePaid(tokenId03);
    priceExpected = BigNumber.from(parseEther(MINT_PRICE)).div(9);
    expect(pricePaid02).to.eq(priceExpected);
    expect(pricePaid03).to.eq(priceExpected);
  });
});

describe("REFUND_TEST", function () {
  it("Should refund for one token ...", async function () {
    const deployTimestamp = (await ethers.provider.getBlock("latest"))
      .timestamp;
    const contract = await RA_NFT.deploy(REFUND_TIME + deployTimestamp);
    await contract.deployed();

    let contractEthBal = await ethers.provider.getBalance(contract.address);
    const acc02EthBal = await ethers.provider.getBalance(account02.address);

    // Mint a token from account02
    let tx = await contract
      .connect(account02)
      .mint(1, { value: parseEther(MINT_PRICE) });

    // Check contract balance aftermint
    expect(contractEthBal).to.eq(0);
    contractEthBal = await ethers.provider.getBalance(contract.address);
    expect(contractEthBal).to.eq(parseEther(MINT_PRICE));

    // Calculate gas used
    let receipt = await tx.wait();
    const tokenId = receipt.logs[0].topics[3]; // get tokenId from event logs
    let gasUsed = receipt.cumulativeGasUsed;
    let gasPrice = receipt.effectiveGasPrice;
    let ethUsed = gasUsed.mul(gasPrice);

    // Check new ETH balance of account02 after mint
    const newAcc02EthBal = await ethers.provider.getBalance(account02.address);
    const diffBal = acc02EthBal.sub(parseEther(MINT_PRICE)).sub(ethUsed);
    expect(newAcc02EthBal).to.eq(diffBal);

    // Check token of return address and account02
    let ownerBal = await contract.balanceOf(owner.address);
    let bal02 = await contract.balanceOf(account02.address);
    expect(ownerBal).to.eq(0);
    expect(bal02).to.eq(1);

    // refund the token
    tx = await contract.connect(account02).refund(tokenId);
    receipt = await tx.wait(); // get tokenId from event logs
    gasUsed = receipt.cumulativeGasUsed;
    gasPrice = receipt.effectiveGasPrice;
    ethUsed = gasUsed.mul(gasPrice);

    // Check the new token balance
    ownerBal = await contract.balanceOf(owner.address);
    bal02 = await contract.balanceOf(account02.address);
    expect(ownerBal).to.eq(1);
    expect(bal02).to.eq(0);

    // Check the contract ETH balance again
    contractEthBal = await ethers.provider.getBalance(contract.address);
    expect(contractEthBal).to.eq(0);
  });

  it("Should refund for multiple mints ...", async function () {
    const deployTimestamp = (await ethers.provider.getBlock("latest"))
      .timestamp;
    const contract = await RA_NFT.deploy(REFUND_TIME + deployTimestamp);
    await contract.deployed();

    let contractEthBal = await ethers.provider.getBalance(contract.address);
    const acc02EthBal = await ethers.provider.getBalance(account02.address);

    // Mint a token from account02
    let tx = await contract
      .connect(account02)
      .mint(9, { value: parseEther(MINT_PRICE) });

    // Check contract balance aftermint
    expect(contractEthBal).to.eq(0);
    contractEthBal = await ethers.provider.getBalance(contract.address);
    expect(contractEthBal).to.eq(parseEther(MINT_PRICE));

    // Calculate gas used
    let receipt = await tx.wait(); // get tokenId from event logs
    const gasUsed = receipt.cumulativeGasUsed;
    const gasPrice = receipt.effectiveGasPrice;
    let ethUsed = gasUsed.mul(gasPrice);

    // console.log("Logs length: ", receipt.logs.length);

    // Check new ETH balance of account02 after mint
    let newAcc02EthBal = await ethers.provider.getBalance(account02.address);
    let diffBal = acc02EthBal.sub(parseEther(MINT_PRICE)).sub(ethUsed);
    expect(newAcc02EthBal).to.eq(diffBal);

    // Check token of return address and account02
    let ownerBal = await contract.balanceOf(owner.address);
    let bal02 = await contract.balanceOf(account02.address);
    expect(ownerBal).to.eq(0);
    expect(bal02).to.eq(9);

    // Batch return token
    for (const log of receipt.logs) {
      const tokenId = log.topics[3];
      tx = await contract.connect(account02).refund(tokenId);
      receipt = await tx.wait();

      contractEthBal = await ethers.provider.getBalance(contract.address);
      // Calculate cumulative ETH usage
      ethUsed = receipt.cumulativeGasUsed
        .mul(receipt.effectiveGasPrice)
        .add(ethUsed);
    }

    // Check the new token balance
    ownerBal = await contract.balanceOf(owner.address);
    bal02 = await contract.balanceOf(account02.address);
    expect(ownerBal).to.eq(9);
    expect(bal02).to.eq(0);

    // Check the contract ETH balance again, should be less than per token price
    contractEthBal = await ethers.provider.getBalance(contract.address);
    expect(contractEthBal).to.lt(parseEther(MINT_PRICE).div(9)); // does not always equal to 0

    // Account balance should be original balance sub ETH used
    newAcc02EthBal = await ethers.provider.getBalance(account02.address);
    diffBal = acc02EthBal.sub(ethUsed).sub(contractEthBal); // Tiny amount remain in contract due to how price paid calculated
    expect(diffBal).to.eq(newAcc02EthBal);
  });

  it("Should not refund for zero price ...", async function () {
    const deployTimestamp = (await ethers.provider.getBlock("latest"))
      .timestamp;
    const contract = await RA_NFT.deploy(REFUND_TIME + deployTimestamp);
    await contract.deployed();

    // Mint a token from account02 with zero price
    const tx = await contract
      .connect(account02)
      .mint(1, { value: MINT_PRICE_ZERO });

    const receipt = await tx.wait();
    const tokenId = receipt.logs[0].topics[3]; // get tokenId from event logs

    // Should be reverted with error
    await expect(
      contract.connect(account02).refund(tokenId)
    ).to.be.revertedWith("RefundZeroAmount()");
  });

  it("Should not refund for inactive return state ...", async function () {
    const contract = await RA_NFT.deploy(REFUND_TIME_ZERO);
    await contract.deployed();

    const isRefundActive = await contract.isRefundActive();
    expect(isRefundActive).to.eq(false);

    // Mint a token from account02
    const tx = await contract
      .connect(account02)
      .mint(1, { value: parseEther(MINT_PRICE) });

    const receipt = await tx.wait();
    const tokenId = receipt.logs[0].topics[3]; // get tokenId from event logs

    // Should be reverted with error
    await expect(
      contract.connect(account02).refund(tokenId)
    ).to.be.revertedWith("RefundIsNotActive()");
  });

  it("Should not refund same token more than once ...", async function () {
    const deployTimestamp = (await ethers.provider.getBlock("latest"))
      .timestamp;
    const contract = await RA_NFT.deploy(REFUND_TIME + deployTimestamp);
    await contract.deployed();

    // Mint a token from account02
    const tx = await contract
      .connect(account02)
      .mint(1, { value: parseEther(MINT_PRICE) });

    const receipt = await tx.wait();
    const tokenId = receipt.logs[0].topics[3]; // get tokenId from event logs

    contract.connect(account02).refund(tokenId);
    // Should be reverted with error
    await expect(
      contract.connect(account02).refund(tokenId)
    ).to.be.revertedWith("RefundCallerNotOwner()");
  });

  it("Should not refund token after you transfer to some one else ...", async function () {
    const deployTimestamp = (await ethers.provider.getBlock("latest"))
      .timestamp;
    const contract = await RA_NFT.deploy(REFUND_TIME + deployTimestamp);
    await contract.deployed();

    // Mint a token from account02
    const tx = await contract
      .connect(account02)
      .mint(1, { value: parseEther(MINT_PRICE) });
    const receipt = await tx.wait();
    const tokenId = receipt.logs[0].topics[3]; // get tokenId from event logs

    await contract
      .connect(account02)
      ["safeTransferFrom(address,address,uint256)"](
        account02.address,
        account03.address,
        tokenId
      );
    const bal02 = await contract.balanceOf(account02.address);
    const bal03 = await contract.balanceOf(account03.address);
    expect(bal02).to.eq(0);
    expect(bal03).to.eq(1);

    // Should be reverted with error
    await expect(
      contract.connect(account02).refund(tokenId)
    ).to.be.revertedWith("RefundCallerNotOwner()");
  });

  it("Should refund if acquired from the secondary sale ...", async function () {
    const deployTimestamp = (await ethers.provider.getBlock("latest"))
      .timestamp;
    const contract = await RA_NFT.deploy(REFUND_TIME + deployTimestamp);
    await contract.deployed();

    // Mint a token from account02
    let tx = await contract
      .connect(account02)
      .mint(1, { value: parseEther(MINT_PRICE) });
    let receipt = await tx.wait();
    const tokenId = receipt.logs[0].topics[3]; // get tokenId from event logs

    // Transfer token from account 02 to 03
    await contract
      .connect(account02)
      ["safeTransferFrom(address,address,uint256)"](
        account02.address,
        account03.address,
        tokenId
      );
    let ownerBal = await contract.balanceOf(owner.address);
    let bal02 = await contract.balanceOf(account02.address);
    let bal03 = await contract.balanceOf(account03.address);
    expect(ownerBal).to.eq(0);
    expect(bal02).to.eq(0);
    expect(bal03).to.eq(1);

    // Check account03 ETH balance
    const acc03EthBal = await ethers.provider.getBalance(account03.address);

    tx = await contract.connect(account03).refund(tokenId);
    receipt = await tx.wait(); // get tokenId from event logs
    const gasUsed = receipt.cumulativeGasUsed;
    const gasPrice = receipt.effectiveGasPrice;
    const ethUsed = gasUsed.mul(gasPrice);

    // Check if account03 can return
    ownerBal = await contract.balanceOf(owner.address);
    bal02 = await contract.balanceOf(account02.address);
    bal03 = await contract.balanceOf(account03.address);
    expect(ownerBal).to.eq(1);
    expect(bal02).to.eq(0);
    expect(bal03).to.eq(0);

    // Check if account03 receive the ETH
    const diffBal = acc03EthBal.add(parseEther(MINT_PRICE)).sub(ethUsed);
    const acc03NewBal = await ethers.provider.getBalance(account03.address);
    expect(acc03NewBal).to.eq(diffBal);
  });

  it("Should be able refund after changing return address ...", async function () {
    const deployTimestamp = (await ethers.provider.getBlock("latest"))
      .timestamp;
    const contract = await RA_NFT.deploy(REFUND_TIME + deployTimestamp);
    await contract.deployed();

    // Mint 2 tokens from account02
    let tx = await contract
      .connect(account02)
      .mint(5, { value: parseEther(MINT_PRICE) });

    let receipt = await tx.wait();
    // const tokenId01 = receipt.logs[0].topics[3];
    const tokenId02 = receipt.logs[1].topics[3];
    const tokenId03 = receipt.logs[2].topics[3];
    const tokenId04 = receipt.logs[3].topics[3];
    // const tokenId05 = receipt.logs[4].topics[3]; // get tokenId from event logs

    // Check the new token balance
    let ownerBal = await contract.balanceOf(owner.address);
    let bal02 = await contract.balanceOf(account02.address);
    let bal03 = await contract.balanceOf(account03.address);
    expect(ownerBal).to.eq(0);
    expect(bal02).to.eq(5);
    expect(bal03).to.eq(0);

    // Return one token to the owner
    tx = await contract.connect(account02).refund(tokenId03); // Test in descending order
    receipt = await tx.wait();
    ownerBal = await contract.balanceOf(owner.address);
    bal02 = await contract.balanceOf(account02.address);
    bal03 = await contract.balanceOf(account03.address);
    expect(ownerBal).to.eq(1);
    expect(bal02).to.eq(4);
    expect(bal03).to.eq(0);

    // Change the return address to account03
    await contract.setReturnAddress(account03.address);
    tx = await contract.connect(account02).refund(tokenId04);
    receipt = await tx.wait();
    ownerBal = await contract.balanceOf(owner.address);
    bal02 = await contract.balanceOf(account02.address);
    bal03 = await contract.balanceOf(account03.address);
    expect(ownerBal).to.eq(1);
    expect(bal02).to.eq(3);
    expect(bal03).to.eq(1);

    tx = await contract.connect(account02).refund(tokenId02);
    receipt = await tx.wait();
    ownerBal = await contract.balanceOf(owner.address);
    bal02 = await contract.balanceOf(account02.address);
    bal03 = await contract.balanceOf(account03.address);
    expect(ownerBal).to.eq(1);
    expect(bal02).to.eq(2);
    expect(bal03).to.eq(2);
  });
});

describe("TOKEN_DATA_TEST", function () {
  it("Check owner data for multiple mints ...", async function () {
    const deployTimestamp = (await ethers.provider.getBlock("latest"))
      .timestamp;
    const contract = await RA_NFT.deploy(REFUND_TIME + deployTimestamp);
    await contract.deployed();

    // Mint a token from account02
    const tx = await contract
      .connect(account02)
      .mint(9, { value: parseEther(String(0.9)) });

    const receipt = await tx.wait();

    // Check ownerOf() and pricePaid() behave correctly
    for (const log of receipt.logs) {
      const tokenId = log.topics[3];
      const address = await contract.ownerOf(tokenId);
      expect(address).to.eq(account02.address);

      const price = await contract.pricePaid(tokenId);
      expect(price).to.eq(parseEther("0.1"));
    }
  });
});

describe("WITHDRAW_TEST", function () {
  it("Should not withdraw zero balance ...", async function () {
    const contract = await RA_NFT.deploy(REFUND_TIME_ZERO);
    await contract.deployed();

    // Try to withdraw when zero balance
    const contractBal = await ethers.provider.getBalance(contract.address);
    expect(contractBal).to.eq(0);
    await expect(contract.connect(owner).withdraw()).to.be.revertedWith(
      "WithdrawZeroBalance()"
    );
  });

  it("Should not withdraw when refund is active ...", async function () {
    const deployTimestamp = (await ethers.provider.getBlock("latest"))
      .timestamp;
    const contract = await RA_NFT.deploy(REFUND_TIME + deployTimestamp);
    await contract.deployed();

    const isRefundActive = await contract.isRefundActive();
    expect(isRefundActive).to.eq(true);

    // Mint one token
    await contract
      .connect(account02)
      .mint(1, { value: parseEther(MINT_PRICE) });

    // Try to withdraw when the sale is not active
    await expect(contract.connect(owner).withdraw()).to.be.revertedWith(
      "WithdrawWhenRefundIsActive()"
    );
  });

  it("Should withdraw when refund is not active ...", async function () {
    const contract = await RA_NFT.deploy(REFUND_TIME_ZERO);
    await contract.deployed();

    const isRefundActive = await contract.isRefundActive();
    expect(isRefundActive).to.eq(false);

    const ownerETHBal = await ethers.provider.getBalance(owner.address);

    // Mint one token
    await contract
      .connect(account02)
      .mint(1, { value: parseEther(MINT_PRICE) });

    // Check the contract balance
    let contractBal = await ethers.provider.getBalance(contract.address);
    expect(contractBal).to.eq(parseEther(MINT_PRICE));

    // Check the contract balance after withdraw
    const tx = await contract.connect(owner).withdraw();
    contractBal = await ethers.provider.getBalance(contract.address);
    expect(contractBal).to.eq(0);

    const receipt = await tx.wait();
    const gasUsed = receipt.cumulativeGasUsed;
    const gasPrice = receipt.effectiveGasPrice;
    const ethUsed = gasUsed.mul(gasPrice);

    // Check the owner ETH balance after the withdraw
    const newOwnerETHBal = await ethers.provider.getBalance(owner.address);
    const diffBal = ownerETHBal.sub(ethUsed).add(parseEther(MINT_PRICE));
    expect(diffBal).to.eq(newOwnerETHBal);
  });
});
