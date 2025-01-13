const prompt = require('prompt');
const hre = require("hardhat");
const { Deployer } = require("@matterlabs/hardhat-zksync-deploy")

function cleanupObj(d) {
  let obj = {};
  obj.Underlying = d[1];
  obj.NewVault = d[2];
  obj.NewStrategy = d[3];
  obj.NewPool = d[4];
  return obj;
}

async function main() {
  console.log("Regular vault deployment with upgradable strategy.");
  console.log("Specify a unique ID (for the JSON), vault's underlying token address, and upgradable strategy implementation name");
  prompt.start();
  const addresses = require("../test/test-config.js");
  const wallet = await zksyncEthers.getWallet()
  const deployer = new Deployer(hre, wallet);

  const {id, underlying, strategyName} = await prompt.get(['id', 'underlying', 'strategyName']);
  const factory = await zksyncEthers.getContractAt("MegaFactory", addresses.Factory.MegaFactory, wallet);

  const StrategyImpl = await deployer.loadArtifact(strategyName);
  const impl = await deployer.deploy(StrategyImpl);
  // const verificationId = await hre.run("verify:verify", {address: impl.target});
  // console.log("Verifying source code. Id:", verificationId);

  console.log("Implementation deployed at:", impl.target);

  await factory.createRegularVaultUsingUpgradableStrategy(id, underlying, impl.target)

  const deployment = cleanupObj(await factory.completedDeployments(id));
  console.log(deployment)
  console.log("======");
  console.log(`${id}: ${JSON.stringify(deployment, null, 2)}`);
  console.log("======");

  console.log("Deployment complete.");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
