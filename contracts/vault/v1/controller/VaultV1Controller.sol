//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IVaultV1Controller} from './IVaultV1Controller.sol';
import {V1PacketTypes} from '../V1PacketTypes.sol';
import {INexus} from '../../../nexus/INexus.sol';
import {BaseVaultV1Controller} from './BaseVaultV1Controller.sol';
import {VaultV1CatalogChecker} from './VaultV1CatalogChecker.sol';
import {IFacetCatalog} from '../../../catalog/IFacetCatalog.sol';

import {VaultFactoryModule} from './modules/VaultFactoryModule.sol';
import {GatewayAdapterModule} from './modules/GatewayAdapterModule.sol';
import {IOUTokenModule} from './modules/IOUTokenModule.sol';

import {StringToAddress, AddressToString} from "../../../utils/StringAddressUtils.sol";

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

error GatewayNotAllowedForVault(
  bytes32 nexusId,
  uint32 vaultId,
  address gatewayAddress
);

contract VaultV1Controller is
  IVaultV1Controller,
  BaseVaultV1Controller,
  Ownable,
  VaultV1CatalogChecker,
  GatewayAdapterModule,
  VaultFactoryModule,
  IOUTokenModule
{
  using StringToAddress for string;
  using AddressToString for address;

  constructor(
    IFacetCatalog _facetCatalog,
    address _facetAddress
  ) VaultV1CatalogChecker(_facetCatalog, _facetAddress) {}

  function deployVault(
    uint16 chainId,
    uint32 vaultId,
    address gatewayAddress
  ) external onlyFacetOwners {
    bytes32 nexusId = keccak256(abi.encodePacked(msg.sender));
    bytes memory innerPayload = abi.encode(nexusId, vaultId);

    _sendPacket(
      chainId,
      V1PacketTypes.CreateVault,
      gatewayAddress,
      innerPayload
    );
  }

  function setPrimaryVaultGateway(
    uint16 chainId,
    uint32 vaultId,
    address gatewayAddress
  ) external onlyFacetOwners {}

  function enableVaultRoutingVersion(
    uint16 chainId,
    uint32 vaultId,
    address gatewayAddress
  ) external onlyFacetOwners {}

  function _handlePacket(
    uint16 senderChainId,
    V1PacketTypes packetType,
    bytes32 nexusId,
    address gatewayAddress,
    bytes memory payload
  ) internal override {
    if (packetType == V1PacketTypes.CreateVault) {
      (uint32 vaultId) = abi.decode(
        payload,
        (uint32)
      );

      _deployVault(nexusId, vaultId, gatewayAddress);
      return;
    }
    if (packetType == V1PacketTypes.EnableGateway) {
      (bytes32 nexusId, string memory gatewayAddressRaw) = abi.decode(
        payload,
        (bytes32, string)
      );

      address gatewayAddress = gatewayAddressRaw.toAddress();

      _enforceAcceptedGateway(nexusId, gatewayAddress);
      _enableNexusRoutingVersion(nexusId, gatewayAddress);
    }
  }

  function _enforceAcceptedGateway(
    bytes32 nexusId,
    address gatewayAddress
  ) internal view {
    if (
      !nexusVaults[nexusId].acceptedGateways[gatewayAddress]
    ) {
      revert GatewayNotAllowedForVault(nexusId, gatewayAddress);
    }
  }
}
