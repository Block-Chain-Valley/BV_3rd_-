require('@nomicfoundation/hardhat-toolbox');

const ALCHEMY_API_KEY = 'CjswbuKPCsplYRSB8wrgWEkRTcUI8Rwn';

const GOERLI_PRIVATE_KEY =
  '777ce0e30975b420364407c0886395024d6dc9583bf86091ea85b314d322a1aa';
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: '0.8.18',
  networks: {
    goerli: {
      url: `https://eth-goerli.g.alchemy.com/v2/${ALCHEMY_API_KEY}`,
      accounts: [GOERLI_PRIVATE_KEY],
    },
  },
};
