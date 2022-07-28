import * as dotenv from 'dotenv'

import { HardhatUserConfig, task } from 'hardhat/config'
import '@nomiclabs/hardhat-ethers'
import '@nomiclabs/hardhat-etherscan'
import '@nomiclabs/hardhat-waffle'
import '@openzeppelin/hardhat-upgrades'
import '@typechain/hardhat'
import 'hardhat-gas-reporter'
import 'hardhat-deploy'
import 'solidity-coverage'

dotenv.config()

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task('accounts', 'Prints the list of accounts', async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners()

  for (const account of accounts) {
    console.log(account.address)
  }
})

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

const config: HardhatUserConfig = {
  networks: {
    localhost: {
      url: 'http://127.0.0.1:8545',
    },
    hardhat: {},
    bsctestnet: {
      url: 'https://speedy-nodes-nyc.moralis.io/89b4f5c6d2fc13792dcaf416/bsc/testnet',
      chainId: 97,
      gasPrice: 20000000000,
      accounts:
        process.env.Memonic !== undefined ? [process.env.Memonic] : [],
    },
    bscmainnet: {
      url: 'https://bsc-dataseed.binance.org/',
      chainId: 56,
      gasPrice: 20000000000,
      accounts:
        process.env.Memonic !== undefined ? [process.env.Memonic] : [],
    },
    avaxfuji: {
      url: 'https://api.avax-test.network/ext/bc/C/rpc',
      chainId: 43113,
      gas: 8000000,
      gasPrice: 26000000000,
      accounts:
        process.env.Memonic !== undefined ? [process.env.Memonic] : [],
    },
    avaxmainnet: {
      url: 'https://api.avax.network/ext/bc/C/rpc',
      gas: 8000000,
      chainId: 43114,
      accounts:
        process.env.Memonic !== undefined ? [process.env.Memonic] : [],
    },
    ropsten: {
      url: 'https://ropsten.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161',
      gas: 8000000,
      chainId: 3,
      accounts:
        process.env.Memonic !== undefined ? [process.env.Memonic] : [],
    },
    rinkeby: {
      url: 'https://rinkeby.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161',
      gas: 8000000,
      chainId: 4,
      accounts:
        process.env.Memonic !== undefined ? [process.env.Memonic] : [],
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: 'USD',
  },
  etherscan: {
    apiKey: {
      rinkeby: 'XFAGSFB6UXE9MFTA9AHJMGHMXI8IXRVCHW',
      ropsten: 'XFAGSFB6UXE9MFTA9AHJMGHMXI8IXRVCHW',
      bsc: 'A263TZTNDWUC9NKI1AMBVJJC8H3SA547AF',
      bscTestnet: 'A263TZTNDWUC9NKI1AMBVJJC8H3SA547AF',
      avalanche: 'WN8CWW97AHIYUBC665Y4HZ4E5V4GUJZR2Y',
      avalancheFujiTestnet: 'WN8CWW97AHIYUBC665Y4HZ4E5V4GUJZR2Y',
    },
  },
  paths: {
    artifacts: './artifacts',
    cache: './cache',
    sources: './contracts',
    tests: './test',
  },
  solidity: {
    // version: '0.8.11',
    // version: '0.6.12',
    compilers: [
      {
        version: '0.8.11',
      },
      {
        version: '0.6.12',
      },
    ],
    overrides: {
      'contracts/Grape.sol': {
        version: '0.6.12',
        settings: {
          optimizer: {
            enabled: true,
            runs: 100,
          },
        },
      },
      'contracts/_Grape.sol': {
        version: '0.8.11',
        settings: {
          optimizer: {
            enabled: true,
            runs: 100,
          },
        },
      },
      'contracts/Cellar.sol': {
        version: '0.8.11',
        settings: {
          optimizer: {
            enabled: true,
            runs: 100,
          },
        },
      },
      'contracts/GrapeFountain.sol': {
        version: '0.8.11',
        settings: {
          optimizer: {
            enabled: true,
            runs: 100,
          },
        },
      },
      'contracts/Upgrade.sol': {
        version: '0.8.11',
        settings: {
          optimizer: {
            enabled: true,
            runs: 100,
          },
        },
      },
      'contracts/VintageWine.sol': {
        version: '0.8.11',
        settings: {
          optimizer: {
            enabled: true,
            runs: 100,
          },
        },
      },
      'contracts/Vintner.sol': {
        version: '0.8.11',
        settings: {
          optimizer: {
            enabled: true,
            runs: 100,
          },
        },
      },
      'contracts/Winery.sol': {
        version: '0.8.11',
        settings: {
          optimizer: {
            enabled: true,
            runs: 100,
          },
        },
      },
      'contracts/WineryProgression.sol': {
        version: '0.8.11',
        settings: {
          optimizer: {
            enabled: true,
            runs: 100,
          },
        },
      },
      'contracts/Multicall.sol': {
        version: '0.8.11',
        settings: {
          optimizer: {
            enabled: true,
            runs: 100,
          },
        },
      },
    },
    settings: {
      optimizer: {
        enabled: true,
      },
    },
  },
}

export default config


// mainnet: "YOUR_ETHERSCAN_API_KEY",
// ropsten: "YOUR_ETHERSCAN_API_KEY",
// rinkeby: "YOUR_ETHERSCAN_API_KEY",
// goerli: "YOUR_ETHERSCAN_API_KEY",
// kovan: "YOUR_ETHERSCAN_API_KEY",
// // binance smart chain
// bsc: "YOUR_BSCSCAN_API_KEY",
// bscTestnet: "YOUR_BSCSCAN_API_KEY",
// // huobi eco chain
// heco: "YOUR_HECOINFO_API_KEY",
// hecoTestnet: "YOUR_HECOINFO_API_KEY",
// // fantom mainnet
// opera: "YOUR_FTMSCAN_API_KEY",
// ftmTestnet: "YOUR_FTMSCAN_API_KEY",
// // optimism
// optimisticEthereum: "YOUR_OPTIMISTIC_ETHERSCAN_API_KEY",
// optimisticKovan: "YOUR_OPTIMISTIC_ETHERSCAN_API_KEY",
// // polygon
// polygon: "YOUR_POLYGONSCAN_API_KEY",
// polygonMumbai: "YOUR_POLYGONSCAN_API_KEY",
// // arbitrum
// arbitrumOne: "YOUR_ARBISCAN_API_KEY",
// arbitrumTestnet: "YOUR_ARBISCAN_API_KEY",
// // avalanche
// avalanche: "YOUR_SNOWTRACE_API_KEY",
// avalancheFujiTestnet: "YOUR_SNOWTRACE_API_KEY",
// // moonbeam
// moonbeam: "YOUR_MOONBEAM_MOONSCAN_API_KEY"
// moonriver: "YOUR_MOONRIVER_MOONSCAN_API_KEY",
// moonbaseAlpha: "YOUR_MOONBEAM_MOONSCAN_API_KEY",
// // harmony
// harmony: "YOUR_HARMONY_API_KEY",
// harmonyTest: "YOUR_HARMONY_API_KEY",
// // xdai and sokol don't need an API key, but you still need
// // to specify one; any string placeholder will work
// xdai: "api-key",
// sokol: "api-key",
// aurora: "api-key",
// auroraTestnet: "api-key",