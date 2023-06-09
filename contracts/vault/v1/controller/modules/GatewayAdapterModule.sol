//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {BaseVaultV1Controller} from '../BaseVaultV1Controller.sol';
import {INexusGateway} from '../../../../gateway/INexusGateway.sol';
import {V1PacketTypes} from '../../types/V1PacketTypes.sol';
import {IVaultGatewayAdapater} from '../../../IVaultGatewayAdapater.sol';

error IncompatibleGateway();
error GatewayAlreadyApproved();
error SenderNotApprovedGateway();
error TargetNotApprovedGateway();

abstract contract GatewayAdapterModule is
  BaseVaultV1Controller,
  IVaultGatewayAdapater
{
  event GatewayApproved(uint32 gatewayId, address gatewayAddress);

  function addApprovedGateway(address gatewayAddress) external onlyOwner {
    if (
      !_supportsERC165Interface(
        gatewayAddress,
        type(INexusGateway).interfaceId
      )
    ) {
      revert IncompatibleGateway();
    }
    if (gateways[INexusGateway(gatewayAddress)] != 0) {
      revert GatewayAlreadyApproved();
    }

    gatewayCount++;

    gateways[INexusGateway(gatewayAddress)] = gatewayCount;
    gatewayVersions[gatewayCount] = INexusGateway(gatewayAddress);

    emit GatewayApproved(gatewayCount, gatewayAddress);
  }

  function handlePacket(
    uint16 senderChainId,
    bytes memory payload
  ) external payable {
    uint32 gatewayId = gateways[INexusGateway(msg.sender)];

    if (gatewayId == 0) {
      revert SenderNotApprovedGateway();
    }

    (
      V1PacketTypes packetType,
      bytes32 nexusId,
      bytes memory innerPayload
    ) = abi.decode(payload, (V1PacketTypes, bytes32, bytes));

    assert(packetType != V1PacketTypes.Never);

    if (!nexusVaults[nexusId].isInitialized) {
      _initializeNexus(nexusId, gatewayId);
    }

    _enforceAcceptedGateway(nexusId, gatewayId);

    _handlePacket(
      senderChainId,
      packetType,
      nexusId,
      innerPayload,
      gatewayId
    );
  }

  function _sendPacket(
    uint16 destinationChainId,
    V1PacketTypes packetType,
    bytes32 nexusId,
    bytes memory innerPayload,
    uint32 transmitUsingGatewayId,
    uint256 gasFeeAmount
  ) internal {
    INexusGateway gateway = gatewayVersions[transmitUsingGatewayId];

    _enforceAcceptedGateway(nexusId, transmitUsingGatewayId);

    gateway.sendPacketTo{value: gasFeeAmount}(
      destinationChainId,
      abi.encode(packetType, nexusId, innerPayload)
    );
  }

  function _handlePacket(
    uint16 senderChainId,
    V1PacketTypes packetType,
    bytes32 nexusId,
    bytes memory payload,
    uint32 gatewayId
  ) internal virtual;
}
