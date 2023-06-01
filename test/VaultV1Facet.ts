import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { deploy, Deployment } from './shared';
import { ethers } from 'hardhat';
import { expect } from 'chai';

describe('VaultV1Facet', () => {
  describe('Functions', () => {
    describe('addLocalAcceptedGateway', () => {
      it('Should return an empty array', async () => {
        const { contractChainId, vaultController, nexus, nexusOwner } =
          await loadFixture(deploy);

        const vaultV1Facet = await ethers.getContractAt(
          'VaultV1Facet',
          nexus.address,
          nexusOwner
        );

        await vaultV1Facet.addLocalAcceptedGateway(1);
      });
    });
    describe('createVaultV1', () => {
      it('Should work', async () => {
        const { nexus, nexusOwner } = await loadFixture(deploy);

        const vaultV1Facet = await ethers.getContractAt(
          'VaultV1Facet',
          nexus.address,
          nexusOwner
        );
        await vaultV1Facet.addLocalAcceptedGateway(1);
        await vaultV1Facet.createVaultV1(1, 1, 1);
      });
    });
  });
});
