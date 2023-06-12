import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { quickDeploy } from './quickDeploy';
import { linkNetworks } from './linkNetworks';

interface Network {
  name: string;
  contractChainId: number;
}

const test_networks = [
  {
    name: 'fantom_testnet',
    contractChainId: 1,
  },
  {
    name: 'polygon_testnet',
    contractChainId: 2,
  },
  {
    name: 'moonbeam_testnet',
    contractChainId: 3,
  },
];
const main_networks = [
  {
    name: 'fantom',
    contractChainId: 1,
  },
  {
    name: 'polygon',
    contractChainId: 2,
  },
  {
    name: 'moonbeam',
    contractChainId: 3,
  },
];

export async function instaDeploy(
  hre: HardhatRuntimeEnvironment,
  isTestnet: boolean
) {
  const networks = isTestnet ? test_networks : main_networks;

  console.log('Deploying...');
  for (var i = 0; i < networks.length; i++) {
    const network = networks[i];
    hre.changeNetwork(network.name);

    await quickDeploy(hre, isTestnet, network.contractChainId);
  }

  console.log('Deploying completed!');
  console.log('Linking...');

  for (var i = 0; i < networks.length; i++) {
    const network = networks[i];
    hre.changeNetwork(network.name);

    await linkNetworks(hre, network.contractChainId, isTestnet);
  }
}
