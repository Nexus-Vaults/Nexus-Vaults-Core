import { loadFixture } from '@nomicfoundation/hardhat-network-helpers';
import { deploy, Deployment } from './shared';
import { ethers } from 'hardhat';
import { expect } from 'chai';

describe('VaultV1', () => {
  it('Should return balances', async () => {
    const factory = await ethers.getContractFactory('VaultV1');

    const vault = await factory.deploy();

    const balance = await vault.getBalance(1, '');
    console.log(balance);
  });
});
