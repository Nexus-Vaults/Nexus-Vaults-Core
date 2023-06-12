import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { writeFileSync, existsSync, readFileSync, mkdirSync } from 'fs';
import {
  ChainDeployment,
  ChainDeploymentParameters,
  GatewayLink,
} from './common';

function getDPath(contractChainId: number, isTestnet: boolean) {
  return isTestnet
    ? `deployment/testnet/${contractChainId}.json`
    : `deployment/mainnet/${contractChainId}.json`;
}
function loadChainDeployment(contractChainId: number, isTestnet: boolean) {
  if (!existsSync(getDPath(contractChainId, isTestnet))) {
    return null;
  }

  const content = readFileSync(
    getDPath(contractChainId, isTestnet),
    'utf-8'
  );
  return JSON.parse(content) as ChainDeployment;
}
function saveChainDeployment(
  contractChainId: number,
  deployment: ChainDeployment,
  isTestnet: boolean
) {
  writeFileSync(
    getDPath(contractChainId, isTestnet),
    JSON.stringify(deployment),
    {
      encoding: 'utf-8',
      flag: 'w',
    }
  );
}

function makeSalt(hre: HardhatRuntimeEnvironment, contractName: string) {
  return hre.ethers.utils.keccak256(
    hre.ethers.utils.toUtf8Bytes(contractName)
  );
}

export async function deployNetwork(
  hre: HardhatRuntimeEnvironment,
  params: ChainDeploymentParameters
) {
  const basePath = params.isTestnet
    ? 'deployment/testnet'
    : 'deployment/mainnet';

  if (!existsSync(basePath)) {
    mkdirSync(basePath);
  }

  console.log('Deploying network...');

  const ethers = hre.ethers;

  var deployment = loadChainDeployment(
    params.contractChainId,
    params.isTestnet
  );

  const owner = (await ethers.getSigners())[0];

  if (deployment == null) {
    console.log('No ChainDeployment found!');
    console.log('Deploying Deployer...');

    const Deployer = await ethers.getContractFactory('Deployer');
    const deployer = await Deployer.deploy();

    await deployer.deployTransaction.wait(10);

    deployment = {
      contractChainId: params.contractChainId,
      deployerAddress: deployer.address,
      axelarChainName: params.axelarChainName,
      gatewayVaultControllerLinked: false,
      links: [],
      facetListings: [],
    } satisfies ChainDeployment;
  }

  const deployer = await ethers.getContractAt(
    'Deployer',
    deployment.deployerAddress
  );

  try {
    if (deployment.diamondLoupeFacetAddress == null) {
      const DiamondLoupeFacet = await ethers.getContractFactory(
        'DiamondLoupeFacet'
      );

      console.log('Deploying DiamondLoupeFacet...');

      await (
        await deployer.deployContract(DiamondLoupeFacet.bytecode, '0x')
      ).wait(1);

      deployment.diamondLoupeFacetAddress =
        await deployer.getDeployedAddress(DiamondLoupeFacet.bytecode);
    }

    if (deployment.nexusFactoryAddress == null) {
      const NexusFactory = await ethers.getContractFactory('NexusFactory');
      const deploymentArgs = new ethers.utils.AbiCoder().encode(
        ['address', 'uint256', 'address'],
        [
          params.feeTokenAddress,
          params.nexusCreationFeeAmount,
          owner.address,
        ]
      );

      console.log('Deploying NexusFactory...');

      await (
        await deployer.deployContract(
          NexusFactory.bytecode,
          deploymentArgs
        )
      ).wait(1);
      deployment.nexusFactoryAddress = await deployer.getDeployedAddress(
        NexusFactory.bytecode
      );
    }

    if (deployment.publicCatalogAddress == null) {
      const FacetCatalog = await ethers.getContractFactory('FacetCatalog');
      const deploymentArgs = new ethers.utils.AbiCoder().encode(
        ['address'],
        [owner.address]
      );

      console.log('Deploying FacetCatalog...');

      await (
        await deployer.deployContract(
          FacetCatalog.bytecode,
          deploymentArgs
        )
      ).wait(1);
      deployment.publicCatalogAddress = await deployer.getDeployedAddress(
        FacetCatalog.bytecode
      );
    }

    const facetCatalog = await ethers.getContractAt(
      'FacetCatalog',
      deployment.publicCatalogAddress
    );

    if (deployment.vaultV1ControllerAddress == null) {
      const VaultV1Controller = await ethers.getContractFactory(
        'VaultV1Controller'
      );
      const deploymentArgs = new ethers.utils.AbiCoder().encode(
        ['uint16', 'address', 'address'],
        [
          params.contractChainId,
          deployment.publicCatalogAddress,
          owner.address,
        ]
      );

      console.log('Deploying VaultV1Controller...');

      await (
        await deployer.deployContract(
          VaultV1Controller.bytecode,
          deploymentArgs
        )
      ).wait(1);
      deployment.vaultV1ControllerAddress =
        await deployer.getDeployedAddress(VaultV1Controller.bytecode);
    }

    const vaultV1Controller = await ethers.getContractAt(
      'VaultV1Controller',
      deployment.vaultV1ControllerAddress
    );

    if (deployment.vaultV1FacetAddress == null) {
      deployment.vaultV1FacetAddress =
        await vaultV1Controller.facetAddress();
    }

    if (deployment.nexusGatewayAddress == null) {
      const NexusGateway = await ethers.getContractFactory('NexusGateway');
      const deploymentArgs = new ethers.utils.AbiCoder().encode(
        ['uint16', 'address', 'address', 'address', 'address'],
        [
          params.contractChainId,
          deployment.vaultV1ControllerAddress,
          params.axelarGatewayAddress,
          params.axelarGasServiceAddress,
          owner.address,
        ]
      );

      console.log('Deploying NexusGateway...');

      await (
        await deployer.deployContract(
          NexusGateway.bytecode,
          deploymentArgs
        )
      ).wait(1);
      deployment.nexusGatewayAddress = await deployer.getDeployedAddress(
        NexusGateway.bytecode
      );
    }

    if (!deployment.gatewayVaultControllerLinked) {
      console.log('Configuring approved gateway...');
      await vaultV1Controller.addApprovedGateway(
        deployment.nexusGatewayAddress
      );

      deployment.gatewayVaultControllerLinked = true;
    }

    if (
      deployment.diamondLoupeFacetAddress != null &&
      !deployment.facetListings.some(
        (x) => x.facetAddress == deployment!.diamondLoupeFacetAddress
      )
    ) {
      console.log('Adding DiamondLoupeFacet offering...');
      await facetCatalog.addOffering(
        deployment.diamondLoupeFacetAddress,
        params.feeTokenAddress,
        0
      );

      deployment.facetListings.push({
        facetAddress: deployment.diamondLoupeFacetAddress,
        feeToken: params.feeTokenAddress,
        feeAmount: 0,
      });
    }

    if (
      deployment.vaultV1FacetAddress != null &&
      !deployment.facetListings.some(
        (x) => x.facetAddress == deployment!.vaultV1FacetAddress
      )
    ) {
      console.log('Adding VaultV1Facet offering...');
      await facetCatalog.addOffering(
        deployment.vaultV1FacetAddress,
        params.feeTokenAddress,
        params.vaultV1FacetFeeAmount
      );

      deployment.facetListings.push({
        facetAddress: deployment.vaultV1FacetAddress,
        feeToken: params.feeTokenAddress,
        feeAmount: 0,
      });
    }
  } catch (error) {
    console.log(error);
  }

  saveChainDeployment(
    params.contractChainId,
    deployment,
    params.isTestnet
  );
}
