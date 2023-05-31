import { HardhatUserConfig, task, types } from 'hardhat/config';
import '@nomicfoundation/hardhat-toolbox';
import 'hardhat-contract-sizer';
import '@nomicfoundation/hardhat-chai-matchers';

import { deployNetwork } from './scripts/deployNetwork';

task('deployNetwork', 'Deploys all contracts to a network')
  .addParam(
    'contractChainId',
    'The contractChainId to set for the routing contracts',
    undefined,
    types.int,
    false
  )
  .addParam(
    'feeTokenAddress',
    'The address of the token to use for fees',
    undefined,
    types.string,
    false
  )
  .addParam(
    'axelarGatewayAddress',
    'The address of the axelar gateway',
    undefined,
    types.string,
    false
  )
  .addParam(
    'axelarGasServiceAddress',
    'The address of the axelar gas service',
    undefined,
    types.string,
    false
  )
  .addParam(
    'nexusCreationFeeAmount',
    'The amount of the fee token to charge for deploying a nexus',
    0,
    types.int,
    true
  )
  .addParam(
    'vaultV1FacetFeeAmount',
    'The amount of fee token to charge for the VaultV1Facet',
    0,
    types.int,
    true
  )
  .setAction(async (taskArgs, hre) => {
    await deployNetwork(
      hre,
      taskArgs.contractChainId,
      taskArgs.feeTokenAddress,
      taskArgs.nexusCreationFeeAmount,
      taskArgs.axelarGatewayAddress,
      taskArgs.axelarGasServiceAddress,
      taskArgs.vaultV1FacetFeeAmount
    );
  });

const config: HardhatUserConfig = {
  solidity: {
    version: '0.8.18',
    settings: {
      optimizer: {
        enabled: true,
        runs: 50,
      },
    },
  },
  etherscan: {
    apiKey: {
      ftmTestnet: 'NGHI15HQVP2KQCKKEKX5NNK94BZ774D618',
    },
  },
  networks: {
    hardhat: {},
    local: {
      url: 'http://127.0.0.1:8545',
      chainId: 31337,
      accounts: [
        '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80',
      ],
    },
    fantom_testnet: {
      url: 'https://rpc.testnet.fantom.network',
      accounts: [
        process.env.EVM_TESTNET_KEY ??
          '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80',
      ],
    },
  },
};

export default config;
