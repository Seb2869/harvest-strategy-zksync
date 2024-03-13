const { Deployer } = require("@matterlabs/hardhat-zksync-deploy")
const { Wallet } = require("zksync-web3")
const secret = require('../dev-keys.json')
const addresses = require("../test/test-config.js")

module.exports =  async function (hre) {
  console.log("Deploying RewardForwarder");
  const mnemonicWallet = ethers.Wallet.fromMnemonic(secret.mnemonic)
  const wallet = new Wallet(mnemonicWallet.privateKey)
  const deployer = new Deployer(hre, wallet);
  const artifact = await deployer.loadArtifact("RewardForwarder");

  const contract = await deployer.deploy(artifact, [addresses.Storage]);

  console.log("Deployment complete. RewardForwarder deployed at:", contract.address);

  const verificationId = await hre.run("verify:verify", {
    address: contract.address,
    constructorArguments: [addresses.Storage],
  });

  console.log("Verifying source code. Id:", verificationId);

  if (addresses.Controller != "0x0000000000000000000000000000000000000000") {
    const IController = await deployer.loadArtifact("IController");
    const controller = await IController.at(addresses.Controller);
    await controller.setRewardForwarder(contract.address);
  
    console.log("Added new RewardForwarder to Controller");  
  }
}