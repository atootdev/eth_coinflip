require("@nomiclabs/hardhat-waffle");
const dotenv = require('dotenv');
dotenv.config();
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const INFURA_KEY = process.env.INFURA_KEY;

module.exports = {
  solidity: "0.8.0",
  paths: {
    artifacts: './src/artifacts',
  },
  networks: {
    hardhat: {
    },
    rinkeby: {
      url: "https://rinkeby.infura.io/v3/" + INFURA_KEY,
      accounts: [`0x${PRIVATE_KEY}`]
    }
  }
};
