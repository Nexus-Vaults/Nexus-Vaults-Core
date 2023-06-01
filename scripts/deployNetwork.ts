import { HardhatRuntimeEnvironment } from 'hardhat/types';
import { writeFileSync, existsSync, mkdirSync } from 'fs';
import { Deployment } from './common';

export async function deployNetwork(
  hre: HardhatRuntimeEnvironment,
  contractChainId: number,
  feeTokenAddress: string,
  nexusCreationFeeAmount: number,
  axelarGatewayAddress: string,
  axelarGasServiceAddress: string,
  axelarChainName: string,
  vaultV1FacetFeeAmount: number
) {
  if (!existsSync('deployment')) {
    mkdirSync('deployment');
  }

  const filePath = `deployment/${contractChainId}.json`;

  if (existsSync(filePath)) {
    throw 'contractChainId already used';
  }

  const { ethers } = hre;

  const signer = (await ethers.getSigners())[0];

  const FacetCatalog = await ethers.getContractFactory('FacetCatalog');
  console.log('Deploying Catalog...');
  const facetCatalog = await FacetCatalog.deploy(signer.address);

  const VaultController = await ethers.getContractFactory(
    'VaultV1Controller'
  );

  console.log('Deploying VaultV1Controller...');
  const vaultController = await VaultController.deploy(
    contractChainId,
    facetCatalog.address
  );

  const NexusGateway = await ethers.getContractFactory('NexusGateway');

  console.log('Deploying NexusGateway...');
  const nexusGateway = await NexusGateway.deploy(
    contractChainId,
    vaultController.address,
    axelarGatewayAddress,
    axelarGasServiceAddress
  );

  console.log('Adding approved gateway...');
  await vaultController.addApprovedGateway(nexusGateway.address);

  const vaultFacet = await ethers.getContractAt(
    'VaultV1Facet',
    await vaultController.facetAddress()
  );

  console.log('Adding vaultV1Facet offering...');
  await facetCatalog.addOffering(
    vaultFacet.address,
    feeTokenAddress,
    vaultV1FacetFeeAmount
  );

  const DiamondLoupeFacet = await ethers.getContractFactory(
    'DiamondLoupeFacet',
    signer
  );

  console.log('Deploying DiamondLoupeFacet...');
  const diamondLoupeFacet = await DiamondLoupeFacet.deploy();

  const NexusFactory = await ethers.getContractFactory('NexusFactory');

  console.log('Deploying NexusFactory...');
  const nexusFactory = await NexusFactory.deploy(
    diamondLoupeFacet.address,
    feeTokenAddress,
    nexusCreationFeeAmount,
    signer.address
  );

  //const nexusAddress = await nexusFactory.callStatic.create(
  //  'TEST_NEXUS',
  //  signer.address,
  //  []
  //);

  //console.log('Deploying TestNexus...');
  //await nexusFactory.create('TEST_NEXUS', signer.address, []);
  //
  //const nexus = await ethers.getContractAt('Nexus', nexusAddress, signer);
  //
  //console.log('Test Nexus At ' + nexus.address);

  const deployment: Deployment = {
    contractChainId: contractChainId,
    axelarChainName: axelarChainName,
    nexusFactoryAddress: nexusFactory.address,
    vaultV1ControllerAddress: vaultController.address,
    nexusGatewayAddress: nexusGateway.address,
    publicCatalogAddress: facetCatalog.address,
    vaultV1FacetAddress: vaultFacet.address,
    links: [],
  };

  writeFileSync(
    `deployment/${contractChainId}.json`,
    JSON.stringify(deployment),
    {
      encoding: 'utf-8',
    }
  );
}
