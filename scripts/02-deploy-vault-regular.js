const prompt = require('prompt');

function cleanupObj(d) {
  let obj = {};
  obj.Underlying = d[1];
  obj.NewVault = d[2];
  obj.NewStrategy = d[3];
  obj.NewPool = d[4];
  return obj;
}

async function main() {
  console.log("Regular vault deployment (no strategy).\nSpecify a unique ID (for the JSON) and the vault's underlying token address");
  prompt.start();
  const addresses = require("../test/test-config.js");

  const {id, underlying} = await prompt.get(['id', 'underlying']);
  const factory = await zksyncEthers.getContractAt("MegaFactory", addresses.Factory.MegaFactory)

  await factory.createRegularVault(id, underlying);

  const deployment = cleanupObj(await factory.completedDeployments(id));
  console.log("======");
  console.log(`${id}: ${JSON.stringify(deployment, null, 2)}`);
  console.log("======");

  console.log("Deployment complete. Add the JSON above to `harvest-api` (https://github.com/harvest-finance/harvest-api/blob/master/data/mainnet/addresses.json) repo and add entries to `tokens.js` and `pools.js`.");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
