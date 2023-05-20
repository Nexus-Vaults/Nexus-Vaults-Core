//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IVaultV1Controller} from './IVaultV1Controller.sol';
import {VaultV1Factory} from './VaultV1Factory.sol';
import {VaultV1GatewayAdapter} from './VaultV1GatewayAdapter.sol';
import {V1PacketTypes} from '../V1PacketTypes.sol';
import {INexus} from '../../../nexus/INexus.sol';
import {BaseVaultV1Controller} from './BaseVaultV1Controller.sol';
import {VaultV1CatalogChecker} from './VaultV1CatalogChecker.sol';
import {IFacetCatalog} from '../../../catalog/IFacetCatalog.sol';

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

error RoutingVersionNotAllowedForVault(
  bytes32 nexusId,
  uint32 vaultId,
  uint16 expectedRoutingVersion,
  uint16 actualRoutingVersion
);

contract VaultV1Controller is
  IVaultV1Controller,
  BaseVaultV1Controller,
  Ownable,
  VaultV1Factory,
  VaultV1GatewayAdapter,
  VaultV1CatalogChecker
{
  constructor(
    IFacetCatalog _facetCatalog,
    address _facetAddress
  ) VaultV1CatalogChecker(_facetCatalog, _facetAddress) {}

  function deployVault(
    uint16 chainId,
    uint32 vaultId,
    uint16 routingVersion
  ) external onlyFacetOwners {
    bytes32 nexusId = keccak256(abi.encodePacked(msg.sender));
    bytes memory innerPayload = abi.encode(nexusId, vaultId);

    _sendPacket(
      chainId,
      V1PacketTypes.CreateVault,
      routingVersion,
      innerPayload
    );
  }

  function setVaultRoutingVersion(
    uint16 chainId,
    uint32 vaultId,
    uint16 routingVersion
  ) external onlyFacetOwners {}

  function _handlePacket(
    uint16 senderChainId,
    V1PacketTypes packetType,
    uint16 routingVersion,
    bytes memory payload
  ) internal override {
    if (packetType == V1PacketTypes.CreateVault) {
      (bytes32 nexusId, uint32 vaultId) = abi.decode(
        payload,
        (bytes32, uint32)
      );

      _deployVault(nexusId, vaultId, routingVersion);
      return;
    }

    if (packetType == V1PacketTypes.SetVaultRoutingVersion) {
      (bytes32 nexusId, uint32 vaultId, uint16 newRoutingVersion) = abi.decode(
        payload,
        (bytes32, uint32, uint16)
      );

      _enforceRoutingVersion(nexusId, vaultId, routingVersion);
      _setVaultRoutingVersion(nexusId, vaultId, newRoutingVersion);
      return;
    }
  }

  function _enforceRoutingVersion(
    bytes32 nexusId,
    uint32 vaultId,
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
