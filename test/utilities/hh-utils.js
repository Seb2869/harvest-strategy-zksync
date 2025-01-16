const makeVault = require("./make-vault.js");
const addresses = require("../test-config.js");
const IUpgradeableStrategy = hre.artifacts.readArtifact("IUpgradeableStrategy");

const Utils = require("./Utils.js");

async function impersonates(targetAccounts){
  console.log("Impersonating...");
  for(i = 0; i < targetAccounts.length ; i++){
    console.log(targetAccounts[i]);
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [
        targetAccounts[i]
      ]
    });
  }
}

async function setupCoreProtocol(config) {
  // Set vault (or Deploy new vault), underlying, underlying Whale,
  // amount the underlying whale should send to farmers
  if(config.existingVaultAddress != null){
    vault = await hre.zksyncEthers.getContractAt("VaultV2", config.existingVaultAddress, config.governance);
    console.log("Fetching Vault at: ", vault.target);
  } else {
    const implAddress = config.vaultImplementationOverride || addresses.VaultImplementation;
    vault = await makeVault(implAddress, addresses.Storage, config.underlying.target, 100, 100, config.governance);
    console.log("New Vault Deployed: ", vault.target);
  }

  controller = await hre.zksyncEthers.getContractAt("IController", addresses.Controller, config.goverance);

  let rewardPool = null;

  if (!config.rewardPoolConfig) {
    config.rewardPoolConfig = {};
  }
  // if reward pool is required, then deploy it
  if(config.rewardPool != null && config.existingRewardPoolAddress == null) {
    const rewardTokens = config.rewardPoolConfig.rewardTokens || [addresses.FARM];
    const rewardDistributions = [config.governance];

    if (config.rewardPoolConfig.type === 'PotPool') {
      const PotPool = hre.artifacts.readArtifact("PotPool");
      console.log("reward pool needs to be deployed");
      rewardPool = await PotPool.new(
        rewardTokens,
        vault.target,
        64800,
        rewardDistributions,
        addresses.Storage,
        "fPool",
        "fPool",
        18,
        {from: config.governance }
      );
      console.log("New PotPool deployed: ", rewardPool.target);
    } else {
      const NoMintRewardPool = hre.artifacts.readArtifact("NoMintRewardPool");
      console.log("reward pool needs to be deployed");
      rewardPool = await NoMintRewardPool.new(
        rewardTokens[0],
        vault.target,
        64800,
        rewardDistributions,
        addresses.Storage,
        "0x0000000000000000000000000000000000000000",
        "0x0000000000000000000000000000000000000000",
        {from: config.governance }
      );
      console.log("New NoMintRewardPool deployed: ", rewardPool.target);
    }
  } else if(config.existingRewardPoolAddress != null) {
    const PotPool = hre.artifacts.readArtifact("PotPool");
    rewardPool = await PotPool.at(config.existingRewardPoolAddress);
    console.log("Fetching Reward Pool deployed: ", rewardPool.target);
  }

  let universalLiquidatorRegistry = await hre.zksyncEthers.getContractAt("IUniversalLiquidatorRegistry", addresses.UniversalLiquidator.UniversalLiquidatorRegistry, config.governance);

  // set liquidation paths
  if(config.liquidation) {
    for (i=0;i<config.liquidation.length;i++) {
      dex = Object.keys(config.liquidation[i])[0];
      await universalLiquidatorRegistry.setPath(
        web3.utils.keccak256(dex),
        config.liquidation[i][dex],
        {gasPrice: config.gasPrice}
      );
      hre.zksyncEthers.provider.send("evm_mine");
      console.log("Set liquidation path:", config.liquidation[i])
    }
  }

  if(config.uniV3Fee) {
    const uniV3Dex = await hre.zksyncEthers.getContractAt("IDex", "0x4CF4ce260E411a1bf55C16aaAE98FfF730D24b19", config.governance);
    for (i=0;i<config.uniV3Fee.length;i++) {
      await uniV3Dex.setFee(config.uniV3Fee[i][0], config.uniV3Fee[i][1], config.uniV3Fee[i][2], {gasPrice: config.gasPrice});
      hre.zksyncEthers.provider.send("evm_mine");
    }
  }

  // default arguments are storage and vault addresses
  config.strategyArgs = config.strategyArgs || [
    addresses.Storage,
    vault.target
  ];

  for(i = 0; i < config.strategyArgs.length ; i++){
    if(config.strategyArgs[i] == "storageAddr") {
      config.strategyArgs[i] = addresses.Storage;
    } else if(config.strategyArgs[i] == "vaultAddr") {
      config.strategyArgs[i] = vault.target;
    } else if(config.strategyArgs[i] == "poolAddr" ){
      config.strategyArgs[i] = rewardPool.target;
    } else if(config.strategyArgs[i] == "universalLiquidatorRegistryAddr"){
      config.strategyArgs[i] = universalLiquidatorRegistry.target;
    }
  }

  let strategyImpl = null;

  if (!config.strategyArtifactIsUpgradable) {
    const strategyFact = await hre.zksyncEthers.getContractFactory(config.strategyArtifact, config.governance);
    strategy = await strategyFact.deploy(...config.strategyArgs);
    hre.zksyncEthers.provider.send("evm_mine");
  } else {
    const strategyFact = await hre.zksyncEthers.getContractFactory(config.strategyArtifact, config.governance);
    strategyImpl = await strategyFact.deploy();
    hre.zksyncEthers.provider.send("evm_mine");
    console.log("Strategy Implementation deployed.");
    const proxyFact = await hre.zksyncEthers.getContractFactory("StrategyProxy", config.governance);
    const strategyProxy = await proxyFact.deploy(strategyImpl.target);
    hre.zksyncEthers.provider.send("evm_mine");
    console.log("Strategy Proxy deployed.")
    strategy = await hre.zksyncEthers.getContractAt(config.strategyArtifact, strategyProxy.target, config.governance);
    await strategy.initializeStrategy(...config.strategyArgs);
    hre.zksyncEthers.provider.send("evm_mine");
    console.log("Strategy initialized.")
  }

  console.log("Strategy Deployed: ", strategy.target);

  if (config.announceStrategy === true) {
    // Announce switch, time pass, switch to strategy
    hre.zksyncEthers.provider.send("evm_mine");
    await vault.announceStrategyUpdate(strategy.target);
    hre.zksyncEthers.provider.send("evm_mine");
    console.log("Strategy switch announced. Waiting...");
    await Utils.waitHours(13);
    hre.zksyncEthers.provider.send("evm_mine");
    await vault.setStrategy(strategy.target);
    hre.zksyncEthers.provider.send("evm_mine");
    await vault.setVaultFractionToInvest(100, 100);
    hre.zksyncEthers.provider.send("evm_mine");
    console.log("Strategy switch completed.");
  } else if (config.upgradeStrategy === true) {
    // Announce upgrade, time pass, upgrade the strategy
    const strategyAsUpgradable = await hre.zksyncEthers.getContractAt("IUpgradeableStrategy", await vault.strategy(), config.governance);
    await hre.zksyncEthers.provider.send("evm_mine");
    await strategyAsUpgradable.scheduleUpgrade(strategyImpl.target);
    await hre.zksyncEthers.provider.send("evm_mine");
    console.log("Upgrade scheduled. Waiting...");
    await Utils.waitHours(13);
    await hre.zksyncEthers.provider.send("evm_mine");
    await strategyAsUpgradable.upgrade();
    await hre.zksyncEthers.provider.send("evm_mine");
    await vault.setVaultFractionToInvest(100, 100);
    await hre.zksyncEthers.provider.send("evm_mine");
    strategy = await await hre.zksyncEthers.getContractAt(config.strategyArtifact, await vault.strategy(), config.governance);
    await hre.zksyncEthers.provider.send("evm_mine");
    console.log("Strategy upgrade completed.");
  } else {
    await vault.connect(config.governance).setStrategy(strategy.target, {gasPrice: config.gasPrice});
    hre.zksyncEthers.provider.send("evm_mine");
  }

  return [controller, vault, strategy, rewardPool];
}

async function depositVault(_farmer, _underlying, _vault, _amount, _gasPrice) {
  await _underlying.connect(_farmer).approve(_vault.target, _amount.toFixed(), {gasPrice: _gasPrice});
  hre.zksyncEthers.provider.send("evm_mine");
  await _vault.connect(_farmer).deposit(_amount.toFixed(), _farmer.address, {gasPrice: _gasPrice});
  hre.zksyncEthers.provider.send("evm_mine");
}

module.exports = {
  impersonates,
  setupCoreProtocol,
  depositVault,
};
