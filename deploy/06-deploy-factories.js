const { Deployer } = require("@matterlabs/hardhat-zksync-deploy")
const { Wallet } = require("zksync-web3")
const secret = require('../dev-keys.json')
const addresses = require("../test/test-config.js")

module.exports =  async function (hre) {
  const mnemonicWallet = ethers.Wallet.fromMnemonic(secret.mnemonic)
  const wallet = new Wallet(mnemonicWallet.privateKey)
  const deployer = new Deployer(hre, wallet);

  // console.log("Deploying PoolFactory");
  // const poolFactArtifact = await deployer.loadArtifact("PotPoolFactory");
  // const poolFactContract = await deployer.deploy(poolFactArtifact);
  // console.log("Deployment complete. PoolFactory deployed at:", poolFactContract.address);
  // const poolFactverificationId = await hre.run("verify:verify", {address: poolFactContract.address});
  // console.log("Verifying source code. Id:", poolFactverificationId);

  console.log("Deploying VaultFactory");
  const vaultFactArtifact = await deployer.loadArtifact("RegularVaultFactory");
  const vaultFactContract = await deployer.deploy(vaultFactArtifact);
  console.log("Deployment complete. VaultFactory deployed at:", vaultFactContract.address);
  // const vaultFactverificationId = await hre.run("verify:verify", {address: vaultFactContract.address});
  // console.log("Verifying source code. Id:", vaultFactverificationId);

  console.log("Deploying StrategyFactory");
  const stratFactArtifact = await deployer.loadArtifact("UpgradableStrategyFactory");
  const stratFactContract = await deployer.deploy(stratFactArtifact);
  console.log("Deployment complete. StrategyFactory deployed at:", stratFactContract.address);
  // const stratFactverificationId = await hre.run("verify:verify", {address: stratFactContract.address});
  // console.log("Verifying source code. Id:", stratFactverificationId);

  console.log("Deploying MegaFactory");
  const megaFactArtifact = await deployer.loadArtifact("MegaFactory");
  const megaFactContract = await deployer.deploy(megaFactArtifact, [addresses.Storage, addresses.CommunityMsig]);
  console.log("Deployment complete. MegaFactory deployed at:", megaFactContract.address);
  // const megaFactverificationId = await hre.run("verify:verify", {
  //   address: megaFactContract.address,
  //   constructorArguments: [
  //     addresses.Storage,
  //     addresses.CommunityMsig,
  //   ],
  // });
  // console.log("Verifying source code. Id:", megaFactverificationId);
 
  await megaFactContract.setVaultFactory(1, vaultFactContract.address);
  await megaFactContract.setPotPoolFactory("0x78Ec50391a38f29B44B84de4e60cbb9E07EfBc53");
  await megaFactContract.setStrategyFactory(1, stratFactContract.address);
  
  // await poolFactContract.setWhitelist(megaFactContract.address, true);
  await vaultFactContract.setWhitelist(megaFactContract.address, true);
  await stratFactContract.setWhitelist(megaFactContract.address, true);

  console.log("Done setting up cross-access");
}