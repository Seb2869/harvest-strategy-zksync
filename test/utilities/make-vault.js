const hre = require("hardhat");

module.exports = async function(implementationAddress, storage, underlying, num, den) {
  const vaultAsProxyFact =  await hre.zksyncEthers.getContractFactory("VaultProxy");
  const vaultAsProxy = await vaultAsProxyFact.deploy(implementationAddress)
  let vault = await hre.zksyncEthers.getContractAt("VaultV2", vaultAsProxy.target);
  await vault.initializeVault(storage, underlying, num, den);
  return vault;
};
