const oldStrategies = [
  "0x4C450a3B4943884C291aaE50F3d6889082eDC6e8",
  "0x08221C536c871b1da15aeFFC00fa241a29037E70",
  "0xB9DD716Dc39f2E7B137c4DF447196F7e12070929",
  "0xB556a89C3f46862B4e876830471617a8CC52eF1F",
  "0xaD8705C5258dDced56Df324A01F8132867bBdaEd",
  "0xf90f9c15e69558Ab15fE44e016278c54643aeC11",
  "0xe20c65Dd7473e971c847819660AE805A9fe7a17F",
  "0xe4D5C45af1F27617403F6e8A7f0cA39C6A8D244f",
  "0x3Bf266767761C41fbe466B36B8b503a45D9B613B",
  "0x5B0C4F060eFde04524A4F99eaa95149F0a2d2A0b",
  "0x02f3BCBcD41d07236e21f6A4ef07B21b4FfACa5f",
  "0xaBfB002A6f63F86c87B4A80aA8b09194905D315d",
  "0x0d36cbCdCb3722465E2A2dC37a5767E7CEdAF475",
  "0x96F914b2bCbcF18939B5862DbE1a222B9D679288",
  "0x0472b18B5f70861BfeBc919Bdc85F9de9896a535",
  "0xf7cB13FE4221D3430a27D6A7870b2B9393F6A86B",
  "0xe5c3142f69a6960317EB78d6Dcf676E6b221c72A",
  "0x616BaF70AB86295665A09Ec7a03AFa1f3DfA9457",
  "0x102C8EF4e398bd3c64F4D719e0c325Bba7226adB",
  "0x19d727962c8a6f724e1f18e33D473Ee9f0d3eFfc",
  "0x6F1C84c89CA54f135687917De21617d422398284",
  "0x845ff6E7c824Ba4f792888bC3A5AD06EF95c4026",
  "0x8d7829914f118eAC46072622Da88E914c699A7a3",
  "0xd424F195199899c84A20e0B6c1b9aF903A7b36E2",
  "0xf289296d03DBb32934eC8644653ccb8B973CB9da",
]

async function main() {
  const wallet = await zksyncEthers.getWallet()
  for (const strategy of oldStrategies) {
    const contract = await zksyncEthers.getContractAt("IStrategy", strategy, wallet);
    try {
      await contract.withdrawAllToVault();
      console.log("Withdrawn all avaialable funds from strategy:", strategy);
    } catch (error) {
      console.error("Failed to withdraw all, trying to doHardWork and withdrawAllToVault again from strategy:", strategy);
      console.error(error);
      try {
        await contract.doHardWork();
        await new Promise(r => setTimeout(r, 3000));
        await contract.withdrawAllToVault();
        console.log("Withdrawn all avaialable funds from strategy:", strategy);
      } catch (error) {
      console.error("Failed to withdraw all avaialable funds from strategy:", strategy);
      console.error(error);
      }
    }
    await new Promise(r => setTimeout(r, 3000));
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
