//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IVaultController} from '../../IVaultController.sol';
import {VaultV1Factory} from './VaultV1Factory.sol';
import {VaultV1GatewayAdapter} from './VaultV1GatewayAdapter.sol';
import {V1PacketTypes} from '../V1PacketTypes.sol';
import {INexus} from '../../../nexus/INexus.sol';
import {BaseVaultV1Controller} from './BaseVaultV1Controller.sol';

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

error RoutingVersionNotAllowedForVault(
  bytes32 nexusId,
  uint256 vaultId,
  uint16 expectedRoutingVersion,
  uint16 actualRoutingVersion
);

contract VaultV1Controller is
  IVaultController,
  BaseVaultV1Controller,
  Ownable,
  VaultV1Factory,
  VaultV1GatewayAdapter
{
  function _handlePacket(
    uint16 senderChainId,
    V1PacketTypes packetType,
    uint16 routingVersion,
    bytes memory payload
  ) internal override {
    if (packetType == V1PacketTypes.CreateVault) {
      (bytes32 nexusId, uint256 vaultId) = abi.decode(
        payload,
        (bytes32, uint256)
      );

      _deployVault(nexusId, vaultId, routingVersion);
      return;
    }

    if (packetType == V1PacketTypes.SetVaultRoutingVersion) {
      (bytes32 nexusId, uint256 vaultId, uint16 newRoutingVersion) = abi.decode(
        payload,
        (bytes32, uint256, uint16)
      );

      _enforceRoutingVersion(nexusId, vaultId, routingVersion);
      _setVaultRoutingVersion(nexusId, vaultId, newRoutingVersion);
      return;
    }
  }

  function _enforceRoutingVersion(
    bytes32 nexusId,
    uint256 vaultId,
    uint16 routingVersion
  ) internal view {
    if (nexusVaults[nexusId].vaults[vaultId].routingVersion != routingVersion) {
      revert RoutingVersionNotAllowedForVault(
        nexusId,
        vaultId,
        nexusVaults[nexusId].vaults[vaultId].routingVersion,
        routingVersion
      );
    }
  }
}
