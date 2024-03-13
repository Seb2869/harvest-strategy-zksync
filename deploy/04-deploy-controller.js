const { Deployer } = require("@matterlabs/hardhat-zksync-deploy")
const { Wallet } = require("zksync-web3")
const secret = require('../dev-keys.json')
const addresses = require("../test/test-config.js")

module.exports =  async function (hre) {
  console.log("Deploying Controller");
  const mnemonicWallet = ethers.Wallet.fromMnemonic(secret.mnemonic)
  const wallet = new Wallet(mnemonicWallet.privateKey)
  const deployer = new Deployer(hre, wallet);
  const artifact = await deployer.loadArtifact("Controller");
  const contract = await deployer.deploy(
    artifact,
    [
      addresses.Storage,
      addresses.WETH,
      addresses.CommunityMsig,
      addresses.ProfitShare,
      addresses.RewardForwarder,
      addresses.UniversalLiquidator,
      43200,
    ],
  );

  console.log("Deployment complete. Controller deployed at:", contract.address);

  const verificationId = await hre.run("verify:verify", {
    address: contract.address,
    constructorArguments: [
      addresses.Storage,
      addresses.WETH,
      addresses.CommunityMsig,
      addresses.ProfitShare,
      addresses.RewardForwarder,
      addresses.UniversalLiquidator,
      43200,
    ],
  });

  console.log("Verifying source code. Id:", verificationId);

  const Storage = await deployer.loadArtifact("Storage");
  const store = await Storage.at(addresses.Storage);
  await store.setController(contract.address);

  console.log("Added new Controller to Storage");
}