const prompt = require('prompt');
const addresses = require("../../test/test-config.js")

async function main() {
    prompt.start();
    const wallet = await zksyncEthers.getWallet()
    
    const registry = await zksyncEthers.getContractAt("IDex", addresses.UniversalLiquidator.Dexes.uniV3.address, wallet);
    await registry.setFee(
      "0x5AEa5775959fBC2557Cc8789bC1bf90A239D9a91",
      "0x1d17CBcF0D6D143135aE902365D2E5e2A16538D4",
      3000,
    );
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
