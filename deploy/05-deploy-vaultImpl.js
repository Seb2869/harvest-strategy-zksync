const { Deployer } = require("@matterlabs/hardhat-zksync-deploy")
const { Wallet } = require("zksync-web3")
const secret = require('../dev-keys.json')
const addresses = require("../test/test-config.js")

module.exports =  async function (hre) {
  console.log("Deploying Vault Implementation");
  const mnemonicWallet = ethers.Wallet.fromMnemonic(secret.mnemonic)
  const wallet = new Wallet(mnemonicWallet.privateKey)
  const deployer = new Deployer(hre, wallet);
  const artifact = await deployer.loadArtifact("VaultV2");
  const contract = await deployer.deploy(artifact);

  console.log("Deployment complete. Vault Implementation deployed at:", contract.address);

  const verificationId = await hre.run("verify:verify", {address: contract.address});

  console.log("Verifying source code. Id:", verificationId);

  await contract.initializeVault(
    addresses.Storage,
    addresses.iFARM,
    10000,
    10000
  );

  console.log("Initialized VaultImplementation");
}