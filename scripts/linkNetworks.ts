import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { readFileSync, readdirSync, writeFileSync } from 'fs';
import { Deployment } from './common';

export async function linkNetworks(
  hre: HardhatRuntimeEnvironment,
  sourceContractChainId: number
) {
  const { ethers } = hre;

  const deployment = JSON.parse(
    readFileSync(`deployment/${sourceContractChainId}.json`, 'utf8')
  ) as Deployment;

  if (deployment.links.length > 0) {
    throw 'Link already exists';
  }

  const targets = readdirSync('../deployment')
    .map((x) => JSON.parse(readFileSync(x, 'utf-8')) as Deployment)
    .filter((x) => x.contractChainId != sourceContractChainId)
    .map((x) => {
      return {
        chainId: x.contractChainId,
        chainName: x.axelarChainName,
        gatewayAddress: x.nexusGatewayAddress,
      };
    });

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
    `deployment/${sourceContractChainId}.json`,
    JSON.stringify(deployment),
    {
      encoding: 'utf-8',
      flag: 'w',
    }
  );
}
