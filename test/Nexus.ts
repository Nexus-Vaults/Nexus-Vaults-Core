import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { deploy } from './shared';
import { expect } from 'chai';
import { ethers } from 'hardhat';

describe('Nexus', () => {
  describe('Deployment', () => {
    it('Should set name', async () => {
      const { nexus } = await loadFixture(deploy);
      expect(await nexus.nexusName()).eq('TEST_NEXUS');
    });
    it('Should set owner', async () => {
      const { nexus, nexusOwnerAddress } = await loadFixture(deploy);
      expect(await nexus.owner()).to.eq(nexusOwnerAddress);
    });
    it('Should install DiamondLoupeFacet', async () => {
      const { nexus, deployer } = await loadFixture(deploy);

      const nexusFacet = await ethers.getContractAt(
        'DiamondLoupeFacet',
        nexus.address,
        deployer
      );

      expect(await nexusFacet.supportsInterface('0x48e2b093')).to.eq(true);
    });
  });
});
