async function main() {
  const strategy = "0xf90f9c15e69558Ab15fE44e016278c54643aeC11";
  const newImpl = "0x178c5dCb6202c01e948779Cb4f495d9Aad0836a9";

  const wallet = await zksyncEthers.getWallet()
  const contract = await zksyncEthers.getContractAt("BaseUpgradeableStrategy", strategy, wallet);
  await contract.scheduleUpgrade(newImpl);

  console.log("Upgrade for", strategy, "to Implementation:", newImpl, "scheduled")
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
