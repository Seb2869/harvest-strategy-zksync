async function main() {
  const strategies = [
    "0xe20c65Dd7473e971c847819660AE805A9fe7a17F",
  ]
  const rewardToken = "0x5A7d6b2F92C77FAD6CCaBd7EE0624E64907Eaf3E";

  const wallet = await zksyncEthers.getWallet()
  for (strategy of strategies) {
    const contract = await zksyncEthers.getContractAt("SyncSwapStrategy", strategy, wallet);
    await contract.addRewardToken(rewardToken);
    await new Promise(r => setTimeout(r, 2000))

    console.log("Added reward token to", strategy, ", Token:", rewardToken)
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
