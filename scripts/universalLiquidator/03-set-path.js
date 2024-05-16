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
        "0x31C2c031fDc9d33e974f327Ab0d9883Eae06cA4A",
        "0x5AEa5775959fBC2557Cc8789bC1bf90A239D9a91",
        "0x703b52F2b28fEbcB60E1372858AF5b18849FE867",
      ]
    );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
