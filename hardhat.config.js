// require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-web3");
require("@matterlabs/hardhat-zksync");
require('hardhat-contract-sizer');
require("@nomiclabs/hardhat-truffle5");

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
      // chainId: 324,
      zksync: true,
      ethNetwork: `https://eth-mainnet.alchemyapi.io/v2/${secret.alchemyKey}`,
      forking: {
        url: `https://mainnet.era.zksync.io`,
        // blockNumber: 31733639, // <-- edit here
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
    local: {
      url: "http://127.0.0.1:8011",
      ethNetwork: "", // in-memory node doesn't support eth node; removing this line will cause an error
      zksync: true,
    }
  },
  solidity: {
    compilers: [
      {
        version: "0.8.24",
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
    runOnCompile: false,
    strict: false,
  },
  etherscan: {
    apiKey: {
      zksync: secret.etherscanAPI,
    },
    customChains: [
      {
        network: "zksync",
        chainId: 324,
        urls: {
          apiURL: "https://api-era.zksync.network/api",
          browserURL: "https://era.zksync.network/"
        }
      }
    ]
  },
};
