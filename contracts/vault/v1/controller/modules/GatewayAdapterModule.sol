//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {BaseVaultV1Controller} from '../BaseVaultV1Controller.sol';
import {INexusGateway} from '../../../../gateway/INexusGateway.sol';
import {V1PacketTypes} from '../../V1PacketTypes.sol';
import {IVaultGatewayAdapater} from '../../../IVaultGatewayAdapater.sol';

error IncompatibleGateway();
error GatewayAlreadyApproved();
error SenderNotApprovedGateway();
error TargetNotApprovedGateway();

abstract contract GatewayAdapterModule is
  BaseVaultV1Controller,
  IVaultGatewayAdapater
{
  event GatewayApproved(address gatewayAddress);

  function addApprovedGateway(address gatewayAddress) external onlyOwner {
    if (
      !_supportsERC165Interface(
        gatewayAddress,
        type(INexusGateway).interfaceId
      )
    ) {
      revert IncompatibleGateway();
    }
    if (gateways[INexusGateway(gatewayAddress)]) {
      revert GatewayAlreadyApproved();
    }

    gateways[INexusGateway(gatewayAddress)] = true;
    emit GatewayApproved(gatewayAddress);
  }

  function handlePacket(
    uint16 senderChainId,
    bytes memory payload
  ) external payable {
    if (!gateways[INexusGateway(msg.sender)]) {
      revert SenderNotApprovedGateway();
    }

    (
      V1PacketTypes packetType,
      bytes32 nexusId,
      bytes memory innerPayload
    ) = abi.decode(payload, (V1PacketTypes, bytes32, bytes));

    assert(packetType != V1PacketTypes.Never);

    _handlePacket(
      senderChainId,
      packetType,
      nexusId,
      msg.sender,
      innerPayload
    );
  }

  function _sendPacket(
    uint16 destinationChainId,
    V1PacketTypes packetType,
    bytes32 nexusId,
    address gatewayAddress,
    bytes memory innerPayload
  ) internal {
    INexusGateway gateway = INexusGateway(gatewayAddress);

    if (!gateways[gateway]) {
      revert TargetNotApprovedGateway();
    }

    gateway.sendPacketTo{value: msg.value}(
      destinationChainId,
      abi.encode(packetType, nexusId, innerPayload)
    );
  }

  function _handlePacket(
    uint16 senderChainId,
    V1PacketTypes packetType,
    bytes32 nexusId,
    address gatewayAddress,
    bytes memory payload
  ) internal virtual;
}
