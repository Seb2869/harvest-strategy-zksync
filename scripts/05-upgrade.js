const prompt = require('prompt');

async function main() {
    prompt.start();
    const {targetAddr} = await prompt.get(['targetAddr']);

    const wallet = await zksyncEthers.getWallet()
    const contract = await zksyncEthers.getContractAt("IUpgradeableStrategy", targetAddr, wallet);
    await contract.upgrade();
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
