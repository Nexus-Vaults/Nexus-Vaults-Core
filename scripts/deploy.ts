import { ethers } from 'hardhat';

async function main() {
  const signer = (await ethers.getSigners())[0];

  const FeeToken = await ethers.getContractFactory('MockERC20');
  const feeToken = await FeeToken.deploy();

  const FacetCatalog = await ethers.getContractFactory('FacetCatalog');
  const facetCatalog = await FacetCatalog.deploy(
    feeToken.address,
    signer.address
  );

  const VaultController = await ethers.getContractFactory(
    'VaultV1Controller'
  );
  const vaultController = await VaultController.deploy(
    1,
    facetCatalog.address
  );

  const vaultFacet = await ethers.getContractAt(
    'VaultV1Facet',
    await vaultController.facetAddress()
  );
  await facetCatalog.addOffering(
    vaultFacet.address,
    10000000000000000000n
  );

  const NexusGateway = await ethers.getContractFactory('NexusGateway');
  const nexusGateway = await NexusGateway.deploy(
    1,
    vaultController.address,
    '0x0000000000000000000000000000000000000001',
    '0x0000000000000000000000000000000000000001'
  );

  await nexusGateway.initialize([]);

  const NexusFactory = await ethers.getContractFactory('NexusFactory');
  const nexusFactory = await NexusFactory.deploy(
    feeToken.address,
    0,
    signer.address
  );

  console.log(`Catalog at ${facetCatalog.address}`);
  console.log(`Nexus Gateway at ${nexusGateway.address}`);
  console.log(`Vault Controller at ${vaultController.address}`);
  console.log(`NexusFactory at ${nexusFactory.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
