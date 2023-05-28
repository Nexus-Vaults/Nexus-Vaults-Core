import { ethers } from 'hardhat';
import { Signer, BigNumber, utils } from 'ethers';
import {
  DiamondLoupeFacet,
  FacetCatalog,
  MockERC20,
  Nexus,
  NexusFactory,
  NexusGateway,
  VaultV1Controller,
  VaultV1Facet,
} from '../typechain-types';

export interface Deployment {
  deployer: Signer;
  deployerAddress: string;
  treasury: Signer;
  treasuryAddress: string;
  bystander: Signer;
  bystanderAddress: string;
  nexusOwner: Signer;
  nexusOwnerAddress: string;

  feeToken: MockERC20;
  facetCatalog: FacetCatalog;
  vaultController: VaultV1Controller;
  vaultV1Facet: VaultV1Facet;
  nexusGateway: NexusGateway;
  nexusFactory: NexusFactory;
  nexus: Nexus;
  diamondLoupeFacet: DiamondLoupeFacet;
}

export async function deploy() {
  const deployer = (await ethers.getSigners())[0];
  const treasury = (await ethers.getSigners())[1];
  const bystander = (await ethers.getSigners())[2];
  const nexusOwner = (await ethers.getSigners())[3];

  const deployerAddress = await deployer.getAddress();
  const treasuryAddress = await treasury.getAddress();
  const bystanderAddress = await bystander.getAddress();
  const nexusOwnerAddress = await nexusOwner.getAddress();

  const FeeToken = await ethers.getContractFactory('MockERC20', deployer);
  const feeToken = await FeeToken.deploy({});

  const FacetCatalog = await ethers.getContractFactory(
    'FacetCatalog',
    deployer
  );
  const facetCatalog = await FacetCatalog.deploy(
    feeToken.address,
    treasuryAddress
  );

  const VaultController = await ethers.getContractFactory(
    'VaultV1Controller',
    deployer
  );
  const vaultController = await VaultController.deploy(
    1,
    facetCatalog.address
  );

  const vaultFacet = await ethers.getContractAt(
    'VaultV1Facet',
    await vaultController.facetAddress(),
    deployer
  );
  await facetCatalog
    .connect(treasury)
    .addOffering(vaultFacet.address, 10000000000000000000n);

  const NexusGateway = await ethers.getContractFactory(
    'NexusGateway',
    deployer
  );
  const nexusGateway = await NexusGateway.deploy(
    1,
    vaultController.address,
    '0x0000000000000000000000000000000000000001',
    '0x0000000000000000000000000000000000000001'
  );

  await nexusGateway.initialize([]);

  const DiamondLoupeFacet = await ethers.getContractFactory(
    'DiamondLoupeFacet',
    deployer
  );
  const diamondLoupeFacet = await DiamondLoupeFacet.deploy();

  const NexusFactory = await ethers.getContractFactory(
    'NexusFactory',
    deployer
  );
  const nexusFactory = await NexusFactory.deploy(
    diamondLoupeFacet.address,
    feeToken.address,
    0,
    treasuryAddress
  );

  const nexusAddress = await nexusFactory.callStatic.create(
    'TEST_NEXUS',
    nexusOwnerAddress
  );
  await nexusFactory
    .connect(deployer)
    .create('TEST_NEXUS', nexusOwnerAddress);
  const nexus = await ethers.getContractAt(
    'Nexus',
    nexusAddress,
    deployer
  );

  return {
    deployer: deployer,
    deployerAddress: deployerAddress,
    treasury: treasury,
    treasuryAddress: treasuryAddress,
    bystander: bystander,
    bystanderAddress: bystanderAddress,
    nexusOwner: nexusOwner,
    nexusOwnerAddress: nexusOwnerAddress,
    facetCatalog: facetCatalog,
    feeToken: feeToken,
    nexusFactory: nexusFactory,
    nexusGateway: nexusGateway,
    vaultController: vaultController,
    vaultV1Facet: vaultFacet,
    nexus: nexus,
    diamondLoupeFacet: diamondLoupeFacet,
  } as Deployment;
}

export function getInterfaceID(contractInterface: utils.Interface) {
  let interfaceID: BigNumber = ethers.constants.Zero;
  const functions: string[] = Object.keys(contractInterface.functions);
  for (let i = 0; i < functions.length; i++) {
    interfaceID = interfaceID.xor(
      contractInterface.getSighash(functions[i])
    );
  }

  return interfaceID;
}
