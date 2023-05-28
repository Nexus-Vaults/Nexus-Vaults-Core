import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { deploy, Deployment } from './shared';
import { expect } from 'chai';

describe('NexusFactory', () => {
  describe('Deployment', () => {
    it('Should set owner to treasury', async () => {
      const { treasuryAddress, nexusFactory } = await loadFixture(deploy);
      expect(await nexusFactory.owner()).to.eq(treasuryAddress);
    });
    it('Should set fee token', async () => {
      const { feeToken, nexusFactory } = await loadFixture(deploy);
      expect(await nexusFactory.feeToken()).to.eq(feeToken.address);
    });
  });
  describe('Functions', () => {
    describe('setFees', () => {
      it('Revert: Sender not treasury', async () => {
        const { bystander, bystanderAddress, nexusFactory } =
          await loadFixture(deploy);
        await expect(
          nexusFactory.connect(bystander).setFees(bystanderAddress, 10)
        ).to.be.revertedWith('Ownable: caller is not the owner');
      });
      it('Success: Sender is treasury', async () => {
        const { treasury, bystanderAddress, nexusFactory } =
          await loadFixture(deploy);
        await expect(
          nexusFactory.connect(treasury).setFees(bystanderAddress, 10)
        ).to.emit(nexusFactory, 'FeesUpdated');

        expect(await nexusFactory.feeToken()).to.eq(bystanderAddress);
        expect(await nexusFactory.feeAmount()).to.eq(10);
      });
    });

    describe('create', () => {
      it('Success: Bystander calls create', async () => {
        const { bystander, bystanderAddress, nexusFactory } =
          await loadFixture(deploy);

        await expect(
          nexusFactory
            .connect(bystander)
            .create('MY_NEXUS', bystanderAddress)
        ).to.emit(nexusFactory, 'NexusDeployed');
      });
    });
  });
});
