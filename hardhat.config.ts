import { HardhatUserConfig, task, types } from 'hardhat/config';
import '@nomicfoundation/hardhat-toolbox';
import 'hardhat-contract-sizer';
import '@nomicfoundation/hardhat-chai-matchers';
import 'hardhat-change-network';

import { quickDeploy } from './scripts/quickDeploy';
import { linkNetworks } from './scripts/linkNetworks';
import { instaDeploy } from './scripts/instaDeploy';

task('quickDeploy')
  .addParam('contractChainId', undefined, undefined, types.int)
  .addParam('mainnet', undefined, undefined, types.boolean, false)
  .setAction(async (params, hre) => {
    await quickDeploy(hre, !params.mainnet, params.contractChainId);
  });

task('linkNetworks')
  .addParam('contractChainId', undefined, undefined, types.int)
  .addParam('mainnet', undefined, undefined, types.boolean, false)
  .setAction(async (params, hre) => {
    await linkNetworks(hre, params.contractChainId, !params.mainnet);
  });

task('instaDeploy')
  .addParam('mainnet', undefined, undefined, types.boolean, false)
  .setAction(async (params, hre) => {
    await instaDeploy(hre, !params.mainnet);
  });

const config: HardhatUserConfig = {
  solidity: {
    version: '0.8.18',
    settings: {
      viaIR: true,
      optimizer: {
        enabled: true,
        runs: 50,
      },
    },
  },
  etherscan: {
    apiKey: {
      ftmTestnet: 'NGHI15HQVP2KQCKKEKX5NNK94BZ774D618',
      opera: 'NGHI15HQVP2KQCKKEKX5NNK94BZ774D618',
      polygonMumbai: '72KJ5YSN3GSYKWW1DAW4KIWUZW7K9P2KPS',
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
    polygon_testnet: {
      url: 'https://rpc-mumbai.maticvigil.com',
      accounts: [
        process.env.EVM_TESTNET_KEY ??
          '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80',
      ],
    },
    bsc_testnet: {
      url: 'https://bsc-testnet.publicnode.com',
      accounts: [
        process.env.EVM_TESTNET_KEY ??
          '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80',
      ],
    },
    moonbeam_testnet: {
      url: 'https://rpc.api.moonbase.moonbeam.network',
      accounts: [
        process.env.EVM_TESTNET_KEY ??
          '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80',
      ],
    },
    polygon: {
      url: 'https://polygon-rpc.com',
      accounts: [
        process.env.EVM_MAINNET_KEY ??
          '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80',
      ],
    },
    fantom: {
      url: 'https://rpcapi.fantom.network',
      accounts: [
        process.env.EVM_MAINNET_KEY ??
          '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80',
      ],
    },
    moonbeam: {
      url: 'https://moonbeam.public.blastapi.io',
      accounts: [
        process.env.EVM_MAINNET_KEY ??
          '0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80',
      ],
    },
  },
};

export default config;
