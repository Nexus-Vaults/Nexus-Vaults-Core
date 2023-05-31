import { HardhatRuntimeEnvironment } from 'hardhat/types';

export async function deployNetwork(
  hre: HardhatRuntimeEnvironment,
  contractChainId: number,
  feeTokenAddress: string,
  nexusCreationFeeAmount: number,
  axelarGatewayAddress: string,
  axelarGasServiceAddress: string,
  vaultV1FacetFeeAmount: number
) {
  const { ethers } = hre;

  const signer = (await ethers.getSigners())[0];

  const FacetCatalog = await ethers.getContractFactory('FacetCatalog');
  const facetCatalog = await FacetCatalog.deploy(signer.address);

  const VaultController = await ethers.getContractFactory(
    'VaultV1Controller'
  );
  const vaultController = await VaultController.deploy(
    contractChainId,
    facetCatalog.address
  );

  const vaultFacet = await ethers.getContractAt(
    'VaultV1Facet',
    await vaultController.facetAddress()
  );
  await facetCatalog.addOffering(
    vaultFacet.address,
    feeTokenAddress,
    vaultV1FacetFeeAmount
  );

  const NexusGateway = await ethers.getContractFactory('NexusGateway');
  const nexusGateway = await NexusGateway.deploy(
    contractChainId,
    vaultController.address,
    axelarGatewayAddress,
    axelarGasServiceAddress
  );

  await nexusGateway.initialize([]);

  const DiamondLoupeFacet = await ethers.getContractFactory(
    'DiamondLoupeFacet',
    signer
  );
  const diamondLoupeFacet = await DiamondLoupeFacet.deploy();

  const NexusFactory = await ethers.getContractFactory('NexusFactory');
  const nexusFactory = await NexusFactory.deploy(
    diamondLoupeFacet.address,
    feeTokenAddress,
    nexusCreationFeeAmount,
    signer.address
  );

  const nexusAddress = await nexusFactory.callStatic.create(
    'TEST_NEXUS',
    signer.address,
    []
  );

  await nexusFactory.create('TEST_NEXUS', signer.address, []);

  const nexus = await ethers.getContractAt('Nexus', nexusAddress, signer);

  console.log(`Catalog at ${facetCatalog.address}`);
  console.log(`Nexus Gateway at ${nexusGateway.address}`);
  console.log(`Vault Controller at ${vaultController.address}`);
  console.log(`NexusFactory at ${nexusFactory.address}`);
  console.log(`Nexus at ${nexus.address}`);
}
