//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {BaseVaultV1Controller} from './BaseVaultV1Controller.sol';
import {INexusGateway} from '../../../gateway/INexusGateway.sol';
import {V1PacketTypes} from '../V1PacketTypes.sol';
import {IVaultGatewayAdapater} from '../../IVaultGatewayAdapater.sol';

error SenderNotApprovedGateway();

abstract contract VaultV1GatewayAdapter is IVaultGatewayAdapater {
  mapping(INexusGateway => bool) public gatewayApprovals;
  mapping(int => INexusGateway) public routingVersions;

  function handlePacket(
    uint16 senderChainId,
    bytes calldata payload
  ) external payable {
    if (!gatewayApprovals[INexusGateway(msg.sender)]) {
      revert SenderNotApprovedGateway();
    }

    (
      V1PacketTypes packetType,
      uint16 routingVersion,
      bytes memory innerPayload
    ) = abi.decode(payload, (V1PacketTypes, uint16, bytes));

    assert(packetType != V1PacketTypes.Empty);

    _handlePacket(senderChainId, packetType, routingVersion, innerPayload);
  }

  function sendPacket() internal {}

  function _handlePacket(
    uint16 senderChainId,
    V1PacketTypes packetType,
    uint16 routingVersion,
    bytes memory payload
  ) internal virtual;
}
