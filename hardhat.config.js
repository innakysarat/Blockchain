require('dotenv').config();
require("@nomiclabs/hardhat-ethers");
 
const endpoint = process.env.URL
const privateKey = process.env.PRIVATE_KEY
 
module.exports = {
  solidity: "0.8.17",
  networks: {
     goerli: {
       url: endpoint,
       accounts: [`0x${privateKey}`]
     }
   },
}

