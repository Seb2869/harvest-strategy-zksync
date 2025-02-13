const changes = [
  {
    vault: '0x71b7b93f27A4DF142e47390d22e9230EF35308B2',
    strategy: '0x697699B2C2Eb2F896d544C93722B29D178a74ABE'
  },
  {
    vault: '0xA168884D6f63e0f4B9d9Ff50848183cE61F9eDd0',
    strategy: '0xE25D5087A4B4B4697c406C17763843b9228d4d94'
  },
  {
    vault: '0xD35bc2E1Ee9EdF00E0Cd7EE515aAe8cE63A64B1A',
    strategy: '0xf2cB38dbd6b2Ba0D9Efd23A6750c23B20d036A6C'
  },
  {
    vault: '0x5837445312f5D8A77a5cFa4A28801D3EEF47bE8B',
    strategy: '0x11eD9a7766A8eeeAd59959d797223fB82f4B8ca7'
  },
  {
    vault: '0x1B51eA0e4EDf4fac001D3CD55d3fAFc1D1f02f26',
    strategy: '0x150aD2dF1911Eaa2479A06796902B0badd0cC1C2'
  },
  {
    vault: '0x0c0c49Ddd458F6a5e487d7Db8E93F94E84A0aeb9',
    strategy: '0xb180eb2D99918f50E095A5e1f454b6510145F631'
  },
  {
    vault: '0xe784412E71108D73708EF4F966A36e3c11FE9231',
    strategy: '0x7AF24230c6601C564852CEc9f0192a01A453eFD5'
  },
  {
    vault: '0xd0d159b4814B30b0E2750eF61D32307D0B3d4bA8',
    strategy: '0xB0bd5Dc52B6fb848589927B5d8b912ae980e30E3'
  },
  {
    vault: '0x2b019028Bf43d94fC9bCD07920Fdc6375adB2fbd',
    strategy: '0x365eEdFfA4B62d5EE0B5bFadBF03777D7bC64A32'
  },
  {
    vault: '0x9033B553Ac4D95E71c83B542624DE05AC0fdb018',
    strategy: '0x79297d50261460e495FE4214053Ae7D14B3bFaE6'
  },
  {
    vault: '0x5C686D4f62dDB5ceA54D38831772599b8Ff75170',
    strategy: '0x1654C92D710411935bDBCE8651D905a028A04FE7'
  },
  {
    vault: '0x995560FD383E99aDe38e9377EAC9f375243C734b',
    strategy: '0x53F307f46c324D9f577a788078bdcF93E0A33311'
  },
  {
    vault: '0x256bc71d47E5420d4089204a6f6257425e285E66',
    strategy: '0x36d1db3bca5B81fbecE4554926911BaA77aE21b6'
  },
  {
    vault: '0xA696db2BDC759F683E5d673F1E25D6DE2A7a1CC7',
    strategy: '0x2aDF72989D1e945B72A08aaa4a57F678F87d6D6f'
  },
  {
    vault: '0x5Dc30b78bF0aFc3A458Caaa5D92F2Bd080C35031',
    strategy: '0xB4F2C1600fC29CF82559D331554e837286a52562'
  },
  {
    vault: '0x7Ed509Bd8da45CcFF906335605c08c70e82fd4D3',
    strategy: '0x013a2c0104A9BD479fb1792CA8EdCC0b65088ABb'
  },
  {
    vault: '0x58A42F6Ff7C199De35C5EA17a961aDb6e1BB14F7',
    strategy: '0xC0826A9cDf2d2506D9a3836491293A2927b5a448'
  },
  {
    vault: '0xa93C961704d8b11B09E6BEf69E1BD2F7A973897B',
    strategy: '0x9F3993FDb8CF4f213eff76b1E5BCf2B6Cdc40153'
  },
  {
    vault: '0xc5d9c0e656f7953d98A3249730b53005Ed09601C',
    strategy: '0x77901673f083E1D6fB4733E01409Ea03fBD9e2BA'
  },
  {
    vault: '0xB679ca84C7b0644e6Fe0e05851a7c71340977BAb',
    strategy: '0xD7a07Cd6c88eE5beaC6731600dF7C838146F2A0b'
  },
  {
    vault: '0x8b951eC568337172E77801EB20ac6b27C4cc5caC',
    strategy: '0x36b5727B4b53D49edB9Be4DE1AeE24AAf416056e'
  },
  {
    vault: '0x2cD2c687BC5E49b963CFC7C0B329fEeaaf088D5b',
    strategy: '0x916F0d5C4C7F2415B7cCC7608dB3de9848fEFC4a'
  },
  {
    vault: '0x78b52Aa66d2dC895c42Fe519A2A58C777a8e30cf',
    strategy: '0xd07F9D817EdED3E6Ef7df98ac8278C84a396e058'
  },
  {
    vault: '0xe5c4F0644E15d0e480d8D38aC97485f8aF9D9781',
    strategy: '0x5608c17e05a889d897AaFA3Ab053cf5f7B62aa9e'
  },
  {
    vault: '0x6047987B668804506133887DB55eEb0A709C73c4',
    strategy: '0xa0B01c1d773f3a5FEF7664371d787D6A364fDf42'
  },
  {
    vault: '0xA79ccaf161f263AE1f2ba595c2239377E317Bd6B',
    strategy: '0xFe0D2ccf908Ff56CD861e5DCAc5544eC5Cb27024'
  },
  {
    vault: '0xcd00f7FbeE3D6A9C719Df8cC0240f5Ec5Ce95E50',
    strategy: '0x6cb7816Cf371f9067479A63FDF7C3BBd5A0c981d'
  },
  {
    vault: '0xC0f64503dd4bF86b44b61b2Cb5fbD66D0f8832De',
    strategy: '0xB976d043b631A4ad05DF596f2Daf34Ee446B69C9'
  }
];

async function main() {
  const wallet = await zksyncEthers.getWallet()
  const contract = await zksyncEthers.getContractAt("RewardPrePay", "0xbB17B5689DcC01A42d976255C20BD86fEe7f96Cf", wallet);
  for (const change of changes) {
    try {
      await contract.initializeStrategy(change.strategy, 0, 0);
      console.log("Initialized pre-pay rewards for strategy:", change.strategy);
    } catch (error) {
      console.error("Failed to initialize pre-pay rewards for strategy:", change.strategy);
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
