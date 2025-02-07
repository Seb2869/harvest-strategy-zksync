async function main() {
  const strategies = [
    "0x38994f778C179Ca8c56f8Fa27308f70645078dc7",
    "0x9404b700fBDee013DA485f8083618D081E559396",
    "0x71c354e3BC7d08557D5b0A6dd9c2EC7A2b230604",
    "0x102C8EF4e398bd3c64F4D719e0c325Bba7226adB",
    "0x19d727962c8a6f724e1f18e33D473Ee9f0d3eFfc",
    "0xaD8705C5258dDced56Df324A01F8132867bBdaEd",
    "0xfb16Ea1E523b446B7C24A9c3b8247fA78DFEB71C",
    "0xCEc8dacBA8d97b6c4aB45a15276f17AC1673B8Aa",
    "0xd424F195199899c84A20e0B6c1b9aF903A7b36E2",
    "0xf289296d03DBb32934eC8644653ccb8B973CB9da",
  ]

  const wallet = await zksyncEthers.getWallet()
  for (strategy of strategies) {
    const contract = await zksyncEthers.getContractAt("BaseUpgradeableStrategy", strategy, wallet);
    await contract.toggleMerklOperator("0xe117ed7Ef16d3c28fCBA7eC49AFAD77f451a6a21", wallet.address);
    await new Promise(r => setTimeout(r, 2000))

    console.log("Toggled Merkl Operator for", strategy, ", Operator:", wallet.address)
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
