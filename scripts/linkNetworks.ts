import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { readFileSync, readdirSync, writeFileSync } from 'fs';
import { ChainDeployment } from './common';

export async function linkNetworks(
  hre: HardhatRuntimeEnvironment,
  sourceContractChainId: number,
  isTestnet: boolean
) {
  const basePath = isTestnet ? 'deployment/testnet' : 'deployment/mainnet';

  const { ethers } = hre;

  const deployment = JSON.parse(
    readFileSync(`${basePath}/${sourceContractChainId}.json`, 'utf8')
  ) as ChainDeployment;

  if (deployment.links.length > 0) {
    return;
  }

  const targets = readdirSync(basePath)
    .map(
      (x) =>
        JSON.parse(
          readFileSync(`${basePath}/${x}`, 'utf-8')
        ) as ChainDeployment
    )
    .filter((x) => x.contractChainId != sourceContractChainId)
    .map((x) => {
      if (x.nexusGatewayAddress == null) {
        throw 'Missing NexusGatewayAddress';
      }

      return {
        chainId: x.contractChainId,
        chainName: x.axelarChainName,
        gatewayAddress: x.nexusGatewayAddress,
      };
    });

  if (deployment.nexusGatewayAddress == null) {
    throw 'Deployment has no NexusGatewayAddress';
  }

  const nexusGateway = await ethers.getContractAt(
    'NexusGateway',
    deployment.nexusGatewayAddress
  );

  console.log('Configuring Axelar Routes...');
  await nexusGateway.initialize(targets);
  console.log(`Successfully configured ${targets.length}!`);

  deployment.links = targets.map((x) => {
    return {
      targetContractChainId: x.chainId,
      targetGatewayAddress: x.gatewayAddress,
    };
  });

  writeFileSync(
    `${basePath}/${sourceContractChainId}.json`,
    JSON.stringify(deployment),
    {
      encoding: 'utf-8',
      flag: 'w',
    }
  );
}
