const prompt = require('prompt');

async function main() {
    prompt.start();

    const {targetAddr} = await prompt.get(['targetAddr']);

    const contract = await zksyncEthers.getContractAt("IUpgradeableStrategy", targetAddr);
    await contract.upgrade();
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
