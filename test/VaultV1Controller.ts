import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { deploy, Deployment } from './shared';
import { ethers } from 'hardhat';
import { expect } from 'chai';

describe('NexusFactory', () => {
  describe('Function', () => {
    describe('listAcceptedGateways', () => {
      it('Should return an empty array', async () => {
        const { contractChainId, vaultController, nexus } =
          await loadFixture(deploy);

        const nexusId = ethers.utils.keccak256(
          new ethers.utils.AbiCoder().encode(
            ['uint16', 'address'],
            [contractChainId, nexus.address]
          )
        );

        const acceptedGatewayIds =
          await vaultController.listAcceptedGateways(nexusId);

        expect(acceptedGatewayIds.length).to.eq(0);
      });
    });
  });
});
