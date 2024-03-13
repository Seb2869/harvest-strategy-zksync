const { Deployer } = require("@matterlabs/hardhat-zksync-deploy")
const { Wallet } = require("zksync-web3")
const secret = require('../dev-keys.json');

module.exports =  async function (hre) {
  console.log("Deploying Storage");
  const mnemonicWallet = ethers.Wallet.fromMnemonic(secret.mnemonic)
  const wallet = new Wallet(mnemonicWallet.privateKey)
  const deployer = new Deployer(hre, wallet);
  const artifact = await deployer.loadArtifact("Storage");

  const contract = await deployer.deploy(artifact);

  console.log("Deployment complete. Storage deployed at:", contract.address);

  const verificationId = await hre.run("verify:verify", {
    address: contract.address,
  });

  console.log("Verifying source code. Id:", verificationId);
}