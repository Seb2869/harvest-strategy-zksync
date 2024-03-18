require("@nomiclabs/hardhat-truffle5");
require("@nomiclabs/hardhat-web3");
require("@matterlabs/hardhat-zksync-ethers");
require("@matterlabs/hardhat-zksync-verify");
require("@matterlabs/hardhat-zksync-solc");
require("@matterlabs/hardhat-zksync-deploy");
require('hardhat-contract-sizer');

const secret = require('./dev-keys.json');

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      accounts: {
        mnemonic: secret.mnemonic,
      },
      chainId: 324,
      zksync: true,
      ethNetwork: `https://eth-mainnet.alchemyapi.io/v2/${secret.alchemyKey}`,
      forking: {
        url: `https://mainnet.era.zksync.io`,
        // blockNumber: 79985280, // <-- edit here
      },
    },
    mainnet: {
      url: `https://mainnet.era.zksync.io`,
      zksync: true,
      ethNetwork: `https://eth-mainnet.alchemyapi.io/v2/${secret.alchemyKey}`,
      accounts: {
        mnemonic: secret.mnemonic,
      },
      verifyURL: 'https://zksync2-mainnet-explorer.zksync.io/contract_verification'
    },
  },
  solidity: {
    compilers: [
      {
        version: "0.6.12",
        settings: {
          optimizer: {
            enabled: true,
            runs: 1,
          },
        },
      },
    ],
  },
  zksolc: {
    // version: "latest",
    compilerSource: "binary",
    settings: {
      optimizer: {
        enabled: true,
        mode: 'z',
        fallback_to_optimizing_for_size: true,
      }
    },
  },
  mocha: {
    timeout: 2000000
  },
  contractSizer: {
    alphaSort: false,
    disambiguatePaths: false,
    runOnCompile: true,
    strict: false,
  },
};
