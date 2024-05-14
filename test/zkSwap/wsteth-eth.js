// Utilities
const Utils = require("../utilities/Utils.js");
const {
  setupCoreProtocol,
  depositVault,
} = require("../utilities/hh-utils.js");

const addresses = require("../test-config.js");
const BigNumber = require("bignumber.js");
const { zksyncEthers } = require("hardhat");

const Strategy = "ZKSwapStrategyMainnet_wstETH_ETH";

// Developed and tested at blockNumber 33964350

// Vanilla Mocha test. Increased compatibility with tools that integrate Mocha.
describe("ZKSync Mainnet zkSwap wstETH-ETH", function() {
  let gasPrice;

  // external contracts
  let underlying;

  // external setup
  let zf = "0x31C2c031fDc9d33e974f327Ab0d9883Eae06cA4A";
  let weth = "0x5AEa5775959fBC2557Cc8789bC1bf90A239D9a91";
  let wsteth = "0x703b52F2b28fEbcB60E1372858AF5b18849FE867";

  // parties in the protocol
  let governance;
  let farmer1;

  // numbers used in tests
  let farmerBalance;

  // Core protocol contracts
  let controller;
  let vault;
  let strategy;

  async function setupExternalContracts() {
    underlying = await zksyncEthers.getContractAt("IERC20", "0x4848204d1Ee4422d91D91b1C89F6D2F9ACe09e2c");
    console.log("Fetching Underlying at: ", underlying.target);
  }

  async function setupBalance(){
    // let etherGiver = await zksyncEthers.getWallet(9);
    // await etherGiver.sendTransaction({to: underlyingWhale, value: new BigNumber(10e18).toFixed(), gasPrice: gasPrice});
    
    // const whale = await zksyncEthers.getImpersonatedSigner(underlyingWhale);
    // farmerBalance = await underlying.balanceOf(whale.address);
    // console.log(farmerBalance);
    // underlying = await underlying.connect(whale);

    // underlying.transfer(farmer1.address, farmerBalance, {gasPrice: gasPrice});
    // await Utils.sleep(10000);
    // await zksyncEthers.providerL2.send("evm_mine");
    // farmerBalance = await underlying.balanceOf(whale.address);
    // console.log(farmerBalance);
    // console.log(await underlying.balanceOf(farmer1.address));
  }

  before(async function() {
    governance = await zksyncEthers.getWallet();
    gasPrice = await zksyncEthers.providerL2.getGasPrice();

    farmer1 = await zksyncEthers.getWallet();
    // let etherGiver = await zksyncEthers.getWallet(9);
    // const tx = await etherGiver.sendTransaction({to: governance.address, value: new BigNumber(10e18).toFixed(), gasPrice: gasPrice});

    await setupExternalContracts();
    [controller, vault, strategy] = await setupCoreProtocol({
      "gasPrice": gasPrice,
      "existingVaultAddress": null,
      "strategyArtifact": Strategy,
      "strategyArtifactIsUpgradable": true,
      "underlying": underlying,
      "governance": governance,
      "liquidation": [{"zkSwap": [zf, weth]}, {"zkSwap": [zf, weth, wsteth]}]
    });

    // whale send underlying to farmers
    await setupBalance();
  });

  describe("Happy path", function() {
    it("Farmer should earn money", async function() {
      let farmerOldBalance = new BigNumber(await underlying.balanceOf(farmer1.address));
      console.log("Old balance:", farmerOldBalance.toFixed());
      await depositVault(farmer1, underlying, vault, farmerOldBalance, gasPrice);
      let hours = 10;
      let blocksPerHour = 300;
      let oldSharePrice;
      let newSharePrice;

      for (let i = 0; i < hours; i++) {
        console.log("loop ", i);

        oldSharePrice = new BigNumber(await vault.getPricePerFullShare());
        await controller.connect(governance).doHardWork(vault.target);
        newSharePrice = new BigNumber(await vault.getPricePerFullShare());

        console.log("old shareprice: ", oldSharePrice.toFixed());
        console.log("new shareprice: ", newSharePrice.toFixed());
        console.log("growth: ", newSharePrice.toFixed() / oldSharePrice.toFixed());

        apr = (newSharePrice.toFixed()/oldSharePrice.toFixed()-1)*(24/(blocksPerHour/1800))*365;
        apy = ((newSharePrice.toFixed()/oldSharePrice.toFixed()-1)*(24/(blocksPerHour/1800))+1)**365;

        console.log("instant APR:", apr*100, "%");
        console.log("instant APY:", (apy-1)*100, "%");

        await Utils.advanceNBlock(blocksPerHour);
      }
      await vault.withdraw(new BigNumber(await vault.balanceOf(farmer1)).toFixed(), { from: farmer1 });
      let farmerNewBalance = new BigNumber(await underlying.balanceOf(farmer1));
      console.log("New balance:", farmerNewBalance.toFixed());
      Utils.assertBNGt(farmerNewBalance, farmerOldBalance);

      apr = (farmerNewBalance.toFixed()/farmerOldBalance.toFixed()-1)*(24/(blocksPerHour*hours/1800))*365;
      apy = ((farmerNewBalance.toFixed()/farmerOldBalance.toFixed()-1)*(24/(blocksPerHour*hours/1800))+1)**365;

      console.log("earned!");
      console.log("APR:", apr*100, "%");
      console.log("APY:", (apy-1)*100, "%");

      await strategy.withdrawAllToVault({from:governance}); // making sure can withdraw all for a next switch

    });
  });
});
