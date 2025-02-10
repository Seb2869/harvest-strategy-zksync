// Utilities
const Utils = require("../utilities/Utils.js");
const {
  setupCoreProtocol,
  depositVault,
} = require("../utilities/hh-utils.js");

const addresses = require("../test-config.js");
const BigNumber = require("bignumber.js");
const { zksyncEthers } = require("hardhat");

const Strategy = "ZerolendFoldStrategyMainnet_USDCe";

// Developed and tested at blockNumber 55464000

// Vanilla Mocha test. Increased compatibility with tools that integrate Mocha.
describe("ZKSync Mainnet Zerolend USDC.e - PrePay reward", function() {
  let gasPrice;

  // external contracts
  let underlying;
  let rewardPrePay;

  // external setup
  let weth = "0x5AEa5775959fBC2557Cc8789bC1bf90A239D9a91";
  let zf = "0x31C2c031fDc9d33e974f327Ab0d9883Eae06cA4A";
  let wrseth = "0xd4169E045bcF9a86cC00101225d9ED61D2F51af2";

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
    underlying = await zksyncEthers.getContractAt("IERC20", "0x3355df6D4c9C3035724Fd0e3914dE96A5a83aaf4");
    console.log("Fetching Underlying at: ", underlying.target);
    rewardPrePay = await zksyncEthers.getContractAt("RewardPrePay", addresses.RewardPrePay);
  }

  before(async function() {
    governance = await zksyncEthers.getWallet();
    gasPrice = await zksyncEthers.providerL2.getGasPrice();

    farmer1 = await zksyncEthers.getWallet();

    await setupExternalContracts();
    [controller, vault, strategy] = await setupCoreProtocol({
      "gasPrice": gasPrice,
      "existingVaultAddress": "0xB679ca84C7b0644e6Fe0e05851a7c71340977BAb",
      "announceStrategy": true,
      "strategyArtifact": Strategy,
      "strategyArtifactIsUpgradable": true,
      "underlying": underlying,
      "governance": governance,
      // "liquidation": [
      //   {"zkSwap": ["0x5A7d6b2F92C77FAD6CCaBd7EE0624E64907Eaf3E", weth, zf]},
      //   {"zkSwap": [zf, weth, wrseth]},
      // ]
    });

    await hre.zksyncEthers.provider.send("evm_mine");
    await rewardPrePay.connect(governance).initializeStrategy(strategy.target, 0, 0);
    await hre.zksyncEthers.provider.send("evm_mine");
  });

  describe("Happy path", function() {
    it("Farmer should earn money", async function() {
      let farmerOldBalance = new BigNumber(await underlying.balanceOf(farmer1.address));
      console.log("Old balance:", farmerOldBalance.toFixed());
      await depositVault(farmer1, underlying, vault, farmerOldBalance, gasPrice);
      let hours = 10;
      let blocksPerHour = 3600*5;
      let oldSharePrice;
      let newSharePrice;

      for (let i = 0; i < hours; i++) {
        console.log("loop ", i);

        await hre.zksyncEthers.provider.send("evm_mine");
        await rewardPrePay.connect(governance).updateReward(strategy.target, new BigNumber(i+1).times(1e18).toFixed());
        await hre.zksyncEthers.provider.send("evm_mine");

        oldSharePrice = new BigNumber(await vault.getPricePerFullShare());
        await hre.zksyncEthers.provider.send("evm_mine");
        await controller.connect(governance).doHardWork(vault.target);
        await hre.zksyncEthers.provider.send("evm_mine");
        newSharePrice = new BigNumber(await vault.getPricePerFullShare());

        console.log("old shareprice: ", oldSharePrice.toFixed());
        console.log("new shareprice: ", newSharePrice.toFixed());
        console.log("growth: ", newSharePrice.toFixed() / oldSharePrice.toFixed());

        apr = (newSharePrice.toFixed()/oldSharePrice.toFixed()-1)*(24/(blocksPerHour/3600))*365;
        apy = ((newSharePrice.toFixed()/oldSharePrice.toFixed()-1)*(24/(blocksPerHour/3600))+1)**365;

        console.log("instant APR:", apr*100, "%");
        console.log("instant APY:", (apy-1)*100, "%");

        await Utils.waitTime(blocksPerHour);
      }
      await vault.withdraw(new BigNumber(await vault.balanceOf(farmer1)).toFixed(), { from: farmer1 });
      let farmerNewBalance = new BigNumber(await underlying.balanceOf(farmer1)).minus(farmerOldBalance);
      console.log("New balance:", farmerNewBalance.toFixed());
      Utils.assertBNGt(farmerNewBalance, farmerOldBalance);

      apr = (farmerNewBalance.toFixed()/farmerOldBalance.toFixed()-1)*(24/(blocksPerHour*hours/3600))*365;
      apy = ((farmerNewBalance.toFixed()/farmerOldBalance.toFixed()-1)*(24/(blocksPerHour*hours/3600))+1)**365;

      console.log("earned!");
      console.log("APR:", apr*100, "%");
      console.log("APY:", (apy-1)*100, "%");

      await strategy.withdrawAllToVault({from:governance}); // making sure can withdraw all for a next switch

    });
  });
});
