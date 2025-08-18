// hardhat.config.cjs
require("dotenv").config({ path: __dirname + "/.env" });
require("@nomicfoundation/hardhat-toolbox");   // includes verify task
require("@okxweb3/hardhat-explorer-verify");   // OKLink verification plugin

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.28",
    settings: {
      optimizer: { enabled: true, runs: 200 },
    },
  },

  paths: {
    sources: "./contracts",
    artifacts: "./artifacts",
  },

  networks: {
    fantom: {
      url: process.env.FANTOM_RPC_URL || "https://rpc.ftm.tools/",
      chainId: 250,
      accounts: process.env.DEPLOYER_PRIVATE_KEY
        ? [process.env.DEPLOYER_PRIVATE_KEY]
        : [],
    },
    fantomTestnet: {
      url: process.env.FANTOM_TESTNET_RPC_URL || "https://rpc.testnet.fantom.network",
      chainId: 4002,
      accounts: process.env.DEPLOYER_PRIVATE_KEY
        ? [process.env.DEPLOYER_PRIVATE_KEY]
        : [],
    },
  },

  etherscan: {
    apiKey: {
      fantom: process.env.OKLINK_API_KEY || "",
      fantomTestnet: process.env.OKLINK_API_KEY || "",
    },
    customChains: [
      {
        network: "fantom",
        chainId: 250,
        urls: {
          apiURL: "https://www.oklink.com/api/v5/explorer/contract/verify-source-code-plugin/ftm",
          browserURL: "https://www.oklink.com/fantom",
        },
      },
      {
        network: "fantomTestnet",
        chainId: 4002,
        urls: {
          apiURL: "https://www.oklink.com/api/v5/explorer/contract/verify-source-code-plugin/ftm_test",
          browserURL: "https://www.oklink.com/fantom-testnet",
        },
      },
    ],
  },
};
