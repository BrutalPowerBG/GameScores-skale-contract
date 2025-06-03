require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.28",
  networks: {
    'skale-nebula-testnet': {
      url: 'https://testnet.skalenodes.com/v1/lanky-ill-funny-testnet',
      chainId: 37084624,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : []
    },
  },
  etherscan: {
    apiKey: {
      'skale-nebula-testnet': 'empty'
    },
    customChains: [
      {
        network: "skale-nebula-testnet",
        chainId: 37084624,
        urls: {
          apiURL: "https://internal.explorer.testnet.skalenodes.com:10031/api",
          browserURL: "https://internal.explorer.testnet.skalenodes.com"
        }
      }
    ]
  },
  sourcify: {
    enabled: true,
    chainId: 37084624
  }
};
