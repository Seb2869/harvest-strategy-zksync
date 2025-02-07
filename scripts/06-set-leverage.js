async function main() {
  const strategy = "0xB9DD716Dc39f2E7B137c4DF447196F7e12070929";
  const vault = "0xD35bc2E1Ee9EdF00E0Cd7EE515aAe8cE63A64B1A";
  const newBorrowTarget = 0;
  // const newCollateral = 599;

  const wallet = await zksyncEthers.getWallet()
  const contract = await zksyncEthers.getContractAt("ReactorFusionFoldStrategy", strategy, wallet);
  // await contract._setCollateralFactorNumerator(newCollateral);
  // await new Promise(r => setTimeout(r, 2000))
  await contract.setBorrowTargetFactorNumerator(newBorrowTarget);
  await new Promise(r => setTimeout(r, 2000))
  // await contract.setFold(true);
  // await new Promise(r => setTimeout(r, 2000))

  const controller = await zksyncEthers.getContractAt("Controller", "0xC04b19b91EBe5DFBE285C89ACDdDBa0f7258c2Be", wallet);
  await controller.doHardWork(vault);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
