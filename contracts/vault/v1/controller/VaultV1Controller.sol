//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IVaultV1Controller} from './IVaultV1Controller.sol';
import {V1PacketTypes} from '../V1PacketTypes.sol';
import {INexus} from '../../../nexus/INexus.sol';
import {BaseVaultV1Controller} from './BaseVaultV1Controller.sol';
import {IFacetCatalog} from '../../../catalog/IFacetCatalog.sol';

import {VaultFactoryModule} from './modules/VaultFactoryModule.sol';
import {GatewayAdapterModule} from './modules/GatewayAdapterModule.sol';
import {IOUTokenModule} from './modules/IOUTokenModule.sol';
import {InspectorModule} from './modules/InspectorModule.sol';

import {StringToAddress, AddressToString} from '../../../utils/StringAddressUtils.sol';

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

contract VaultV1Controller is
  IVaultV1Controller,
  Ownable,
  BaseVaultV1Controller,
  GatewayAdapterModule,
  VaultFactoryModule,
  IOUTokenModule,
  InspectorModule
{
  using StringToAddress for string;
  using AddressToString for address;

  constructor(
    IFacetCatalog _facetCatalog,
    address _facetAddress
  ) BaseVaultV1Controller(_facetCatalog, _facetAddress) {}

  function deployVault(
    uint16 chainId,
    uint32 vaultId,
    address transmitUsing
  ) external onlyFacetOwners {
    bytes32 nexusId = keccak256(abi.encodePacked(msg.sender));
    bytes memory innerPayload = abi.encode(vaultId);

    _sendPacket(chainId, V1PacketTypes.CreateVault, nexusId, transmitUsing, innerPayload);
  }

  function addAcceptedGateway(
    uint16 chainId,
    address gatewayToAdd,
    address transmitUsing
  ) external onlyFacetOwners {
    bytes32 nexusId = keccak256(abi.encodePacked(msg.sender));
    bytes memory innerPayload = abi.encode(gatewayToAdd);

    _sendPacket(chainId, V1PacketTypes.EnableGateway, nexusId, transmitUsing, innerPayload);
  }

  function _handlePacket(
    uint16 senderChainId,
    V1PacketTypes packetType,
    bytes32 nexusId,
    address gatewayAddress,
    bytes memory payload
  ) internal override {
    if (packetType == V1PacketTypes.CreateVault) {
      uint32 vaultId = abi.decode(payload, (uint32));

      _deployVault(nexusId, vaultId);
      return;
    }
    if (packetType == V1PacketTypes.EnableGateway) {
      string memory addedGatewayAddressRaw = abi.decode(payload, (string));

      address addedGatewayAddress = addedGatewayAddressRaw.toAddress();

      _enforceAcceptedGateway(nexusId, gatewayAddress);
      _addAcceptedGatewayToNexus(nexusId, addedGatewayAddress);
    }
  }
}
