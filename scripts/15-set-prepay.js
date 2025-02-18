const addresses = require("../test/test-config.js");
const toUpgrade =
[
  "0x916F0d5C4C7F2415B7cCC7608dB3de9848fEFC4a",
  "0x36b5727B4b53D49edB9Be4DE1AeE24AAf416056e",
  "0x77901673f083E1D6fB4733E01409Ea03fBD9e2BA",
  "0x9F3993FDb8CF4f213eff76b1E5BCf2B6Cdc40153",
  "0xB976d043b631A4ad05DF596f2Daf34Ee446B69C9",
  "0x6cb7816Cf371f9067479A63FDF7C3BBd5A0c981d",
  "0xFe0D2ccf908Ff56CD861e5DCAc5544eC5Cb27024",
  "0x5608c17e05a889d897AaFA3Ab053cf5f7B62aa9e",
  "0xd07F9D817EdED3E6Ef7df98ac8278C84a396e058",
  "0x1654C92D710411935bDBCE8651D905a028A04FE7",
  "0x79297d50261460e495FE4214053Ae7D14B3bFaE6",
  "0x7AF24230c6601C564852CEc9f0192a01A453eFD5",
  "0xb180eb2D99918f50E095A5e1f454b6510145F631",
  "0x11eD9a7766A8eeeAd59959d797223fB82f4B8ca7",
  "0xf2cB38dbd6b2Ba0D9Efd23A6750c23B20d036A6C",
  "0x9a0217fDc3F883E485Ca5AcC6b790c4f0fc96bEF",
  "0xC0826A9cDf2d2506D9a3836491293A2927b5a448",
  "0x013a2c0104A9BD479fb1792CA8EdCC0b65088ABb",
  "0xB4F2C1600fC29CF82559D331554e837286a52562",
]

async function main() {
  const wallet = await zksyncEthers.getWallet()
  for (const targetAddr of toUpgrade) {
    const contract = await zksyncEthers.getContractAt("IUpgradeableStrategy", targetAddr, wallet);
    await contract.setRewardPrePay(addresses.RewardPrePay);
    console.log(`Set RewardPrePay to: ${addresses.RewardPrePay}, for strategy: ${targetAddr}`);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
