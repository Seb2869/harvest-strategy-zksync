const prompt = require('prompt');
const hre = require("hardhat");
const { Deployer } = require("@matterlabs/hardhat-zksync-deploy")
const ethers = require("ethers");

const addresses = require("../../test/test-config.js")

async function main() {
    prompt.start();
    const wallet = await zksyncEthers.getWallet()
    const deployer = new Deployer(hre, wallet);
    
    const registry = await zksyncEthers.getContractAt("UniversalLiquidatorRegistry", addresses.UniversalLiquidator.UniversalLiquidatorRegistry);
    await registry.setPath(
      "0x746a7e35f0e9af893aaa81941f48da6501a31965ca8691686d79c3d56c165cad",
      [
        "0x5A7d6b2F92C77FAD6CCaBd7EE0624E64907Eaf3E",
        "0x5AEa5775959fBC2557Cc8789bC1bf90A239D9a91",
        "0x3355df6D4c9C3035724Fd0e3914dE96A5a83aaf4",
      ]
    );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
