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
  contractChainId: number;

  contractDeployer: Signer;
  contractDeployerAddress: string;
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
}

export async function deploy() {
  const contractDeployer = (await ethers.getSigners())[0];
  const treasury = (await ethers.getSigners())[1];
  const bystander = (await ethers.getSigners())[2];
  const nexusOwner = (await ethers.getSigners())[3];

  const contractDeployerAddress = await contractDeployer.getAddress();
  const treasuryAddress = await treasury.getAddress();
  const bystanderAddress = await bystander.getAddress();
  const nexusOwnerAddress = await nexusOwner.getAddress();

  const FeeToken = await ethers.getContractFactory(
    'MockERC20',
    contractDeployer
  );
  const feeToken = await FeeToken.deploy({});

  const Deployer = await ethers.getContractFactory(
    'Deployer',
    contractDeployer
  );
  const deployer = await Deployer.deploy();

  const DiamondLoupeFacet = await ethers.getContractFactory(
    'DiamondLoupeFacet'
  );

  await deployer.deployContract(DiamondLoupeFacet.bytecode, '0x');

  const NexusFactory = await ethers.getContractFactory('NexusFactory');

  await deployer.deployContract(
    NexusFactory.bytecode,
    new ethers.utils.AbiCoder().encode(
      ['address', 'uint256', 'address'],
      [feeToken.address, 0, treasuryAddress]
    )
  );

  const FacetCatalog = await ethers.getContractFactory('FacetCatalog');

  await deployer.deployContract(
    FacetCatalog.bytecode,
    new ethers.utils.AbiCoder().encode(['address'], [treasuryAddress])
  );

  const facetCatalog = await ethers.getContractAt(
    'FacetCatalog',
    await deployer.getDeployedAddress(FacetCatalog.bytecode),
    contractDeployer
  );

  const VaultV1Controller = await ethers.getContractFactory(
    'VaultV1Controller',
    contractDeployer
  );

  console.log('2');
  await deployer.deployContract(VaultV1Controller.bytecode, '0x');
  console.log('3');
  const vaultV1Controller = await ethers.getContractAt(
    'VaultV1Controller',
    await deployer.getDeployedAddress(VaultV1Controller.bytecode)
  );

  const NexusGateway = await ethers.getContractFactory('NexusGateway');

  await deployer.deployContract(
    NexusGateway.bytecode,
    new ethers.utils.AbiCoder().encode(
      ['uint16', 'address', 'address', 'address', 'address'],
      [
        1,
        vaultV1Controller.address,
        '0x0000000000000000000000000000000000000000',
        '0x0000000000000000000000000000000000000000',
        treasuryAddress,
      ]
    )
  );
  console.log('4');
  const nexusGateway = await ethers.getContractAt(
    'NexusGateway',
    await deployer.getDeployedAddress(NexusGateway.bytecode)
  );

  await vaultV1Controller.addApprovedGateway(nexusGateway.address);

  await facetCatalog.addOffering(
    await vaultV1Controller.facetAddress(),
    feeToken.address,
    0
  );

  const nexusFactory = await ethers.getContractAt(
    'NexusFactory',
    await deployer.getDeployedAddress(NexusFactory.bytecode)
  );
  console.log('5');
  const vaultV1Facet = await ethers.getContractAt(
    'VaultV1Facet',
    await vaultV1Controller.facetAddress()
  );

  return {
    contractChainId: 1,
    contractDeployer: contractDeployer,
    contractDeployerAddress: contractDeployer.address,
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
    vaultController: vaultV1Controller,
    vaultV1Facet: vaultV1Facet,
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
