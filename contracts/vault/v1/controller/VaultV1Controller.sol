//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IVaultController} from '../../IVaultController.sol';
import {VaultV1Factory} from './VaultV1Factory.sol';
import {VaultV1GatewayAdapter} from './VaultV1GatewayAdapter.sol';
import {V1PacketTypes} from '../V1PacketTypes.sol';
import {INexus} from '../../../nexus/INexus.sol';

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

contract VaultV1Controller is
  IVaultController,
  Ownable,
  VaultV1Factory,
  VaultV1GatewayAdapter
{
  function _handlePacket(
    uint16 senderChainId,
    V1PacketTypes packetType,
    int routingVersion,
    bytes memory payload
  ) internal override {
    if (packetType == V1PacketTypes.CreateVault) {
      (bytes32 nexusId, uint256 vaultId) = abi.decode(
        payload,
        (bytes32, uint256)
      );
      _deployVault(nexusId, vaultId);
      return;
    }
  }
}
