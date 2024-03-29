import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: "0.8.7",
};

export default config;

import "@nomiclabs/hardhat-web3";

import "@nomiclabs/hardhat-truffle5";

import "solidity-coverage";