// Utilities
const Utils = require("../utilities/Utils.js");
const {
  setupCoreProtocol,
  depositVault,
} = require("../utilities/hh-utils.js");

const addresses = require("../test-config.js");
const BigNumber = require("bignumber.js");
const { zksyncEthers } = require("hardhat");

const Strategy = "VenusFoldStrategyMainnet_ZK";

// Developed and tested at blockNumber 53801130

// Vanilla Mocha test. Increased compatibility with tools that integrate Mocha.
describe("ZKSync Mainnet Venus ZK", function() {
  let gasPrice;

  // external contracts
  let underlying;

  // external setup
  let zk;
  let weth = "0x5AEa5775959fBC2557Cc8789bC1bf90A239D9a91";
  let xvs = "0xD78ABD81a3D57712a3af080dc4185b698Fe9ac5A";

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
    underlying = await zksyncEthers.getContractAt("IERC20", "0x5A7d6b2F92C77FAD6CCaBd7EE0624E64907Eaf3E");
    console.log("Fetching Underlying at: ", underlying.target);
  }

  before(async function() {
    governance = await zksyncEthers.getWallet();
    gasPrice = await zksyncEthers.providerL2.getGasPrice();

    farmer1 = await zksyncEthers.getWallet();

    await setupExternalContracts();
    [controller, vault, strategy] = await setupCoreProtocol({
      "gasPrice": gasPrice,
      "existingVaultAddress": null,
      "strategyArtifact": Strategy,
      "strategyArtifactIsUpgradable": true,
      "underlying": underlying,
      "governance": governance,
      "liquidation": [
        {"uniV3": [xvs, weth]},
        {"uniV3": [weth, xvs]},
        {"zkSwap": [weth, "0x5A7d6b2F92C77FAD6CCaBd7EE0624E64907Eaf3E"]},
      ],
      "uniV3Fee": [
        [xvs, weth, 3000],
      ]
    });

    zk = await zksyncEthers.getContractAt("IERC20", "0x5A7d6b2F92C77FAD6CCaBd7EE0624E64907Eaf3E", governance);
  });

  describe("Happy path", function() {
    it("Farmer should earn money", async function() {
      let farmerOldBalance = new BigNumber(await underlying.balanceOf(farmer1.address)).div(2);
      console.log("Old balance:", farmerOldBalance.toFixed());
      await depositVault(farmer1, underlying, vault, farmerOldBalance, gasPrice);
      let hours = 10;
      let blocksPerHour = 200;
      let oldSharePrice;
      let newSharePrice;

      for (let i = 0; i < hours; i++) {
        console.log("loop ", i);
        if (i == 1) {
          let balance = new BigNumber(await zk.balanceOf(governance.address));
          console.log("ZK Balance to transfer:", balance.toFixed());
          await hre.zksyncEthers.provider.send("evm_mine");
          await zk.transfer(strategy.target, balance.toFixed());
          await hre.zksyncEthers.provider.send("evm_mine");
          await strategy._updateZkDist(balance.toFixed());
          await hre.zksyncEthers.provider.send("evm_mine");
        }
        let zkPerSec = new BigNumber(await strategy.zkPerSec());
        let zkBalance = new BigNumber(await zk.balanceOf(strategy.target));
        console.log("ZK per second:", zkPerSec.toFixed());
        console.log("Strategy ZK balance:", zkBalance.toFixed());

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

        await Utils.advanceNBlock(blocksPerHour);
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
