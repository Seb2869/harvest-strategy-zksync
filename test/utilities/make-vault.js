const hre = require("hardhat");
const Vault = hre.artifacts.readArtifact("VaultV2");
const VaultProxy = hre.artifacts.readArtifact("VaultProxy");

module.exports = async function(implementationAddress, ...args) {
  const fromParameter = args[args.length - 1]; // corresponds to {from: governance}
  const implFact = await zksyncEthers.getContractFactory("VaultV2");
  const impl = await implFact.deploy();
  const vaultAsProxyFact =  await hre.zksyncEthers.getContractFactory("VaultProxy");
  const vaultAsProxy = await vaultAsProxyFact.deploy(impl.target)
  const vault = await zksyncEthers.getContractAt("VaultV2", vaultAsProxy.target);
  await vault.initializeVault(...args);
  return vault;
};
