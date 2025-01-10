const hre = require("hardhat");

module.exports = async function(implementationAddress, storage, underlying, num, den, signer) {
  const vaultAsProxyFact =  await hre.zksyncEthers.getContractFactory("VaultProxy", signer);
  const vaultAsProxy = await vaultAsProxyFact.deploy(implementationAddress);
  hre.zksyncEthers.provider.send("evm_mine");
  let vault = await hre.zksyncEthers.getContractAt("VaultV2", vaultAsProxy.target, signer);
  await vault.initializeVault(storage, underlying, num, den);
  hre.zksyncEthers.provider.send("evm_mine");
  return vault;
};
