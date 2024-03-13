const { Deployer } = require("@matterlabs/hardhat-zksync-deploy")
const { Wallet } = require("zksync-web3")
const secret = require('../dev-keys.json')
const addresses = require("../test/test-config.js")

module.exports =  async function (hre) {
  console.log("Deploying ProfitSharingReceiver");
  const mnemonicWallet = ethers.Wallet.fromMnemonic(secret.mnemonic)
  const wallet = new Wallet(mnemonicWallet.privateKey)
  const deployer = new Deployer(hre, wallet);
  const artifact = await deployer.loadArtifact("ProfitSharingReceiver");

  const contract = await deployer.deploy(artifact, [addresses.Storage]);

  console.log("Deployment complete. ProfitSharingReceiver deployed at:", contract.address);

  const verificationId = await hre.run("verify:verify", {
    address: contract.address,
    constructorArguments: [addresses.Storage],
  });

  console.log("Verifying source code. Id:", verificationId);
}