async function main() {
  const strategies = [
    "0x221adBaDaC01A941a767Cae03C56786bdB4fE716",
    "0xA559D2822c3B2c3f82394E9F5788fb9AAB0cDa01",
  ]
  const setStake = false

  const wallet = await zksyncEthers.getWallet()
  for (strategy of strategies) {
    const contract = await zksyncEthers.getContractAt("SyncSwapStrategy", strategy, wallet);
    await contract.setStake(setStake);
    await new Promise(r => setTimeout(r, 2000))

    console.log("Set Stake for", strategy, ", Value:", setStake)
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
