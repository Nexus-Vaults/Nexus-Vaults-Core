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
  describe('Functions', () => {
    describe('installFacet', () => {
      it('Fail: Caller not owner', async () => {
        const { nexus, deployer, bystander, vaultV1Facet } =
          await loadFixture(deploy);

        await expect(
          nexus.connect(deployer).installFacet(vaultV1Facet.address)
        ).to.be.revertedWithCustomError(nexus, 'MustBeOwner');
        await expect(
          nexus.connect(bystander).installFacet(vaultV1Facet.address)
        ).to.be.revertedWithCustomError(nexus, 'MustBeOwner');
      });
      it('Fail: Install already installed facet', async () => {
        const { nexus, nexusOwner, diamondLoupeFacet } = await loadFixture(
          deploy
        );

        await expect(
          nexus.connect(nexusOwner).installFacet(diamondLoupeFacet.address)
        ).to.be.revertedWithCustomError(
          nexus,
          'CannotInstallSelectorThatAlreadyExists'
        );
      });
      it('Success: Owner install valid facet', async () => {
        const { nexus, nexusOwner, vaultV1Facet } = await loadFixture(
          deploy
        );

        await nexus.connect(nexusOwner).installFacet(vaultV1Facet.address);
      });
    });
  });
});
