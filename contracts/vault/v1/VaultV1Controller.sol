//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {INexusGateway} from '../../gateway/INexusGateway.sol';
import {IVaultController} from '../IVaultController.sol';
import {VaultV1Factory} from './VaultV1Factory.sol';
import {V1PacketTypes} from './V1PacketTypes.sol';
import {INexus} from '../../nexus/INexus.sol';

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

error SenderNotApprovedGateway();

contract VaultV1Controller is Ownable, VaultV1Factory, IVaultController {
  mapping(INexusGateway => bool) public gatewayApprovals;
  mapping(int => INexusGateway) public routingVersions;
  mapping(INexus => int) public nexusGatewaySelections; //Only for local Nexus contracts

  function handlePacket(
    uint16 senderChainId,
    bytes calldata payload
  ) external payable {
    if (!gatewayApprovals[INexusGateway(msg.sender)]) {
      revert SenderNotApprovedGateway();
    }

    (
      V1PacketTypes packetType,
      int routingVersion,
      bytes memory innerPayload
    ) = abi.decode(payload, (V1PacketTypes, int, bytes));

    assert(packetType != V1PacketTypes.Empty);

    if (packetType == V1PacketTypes.CreateVault) {
      bytes32 nexusId = abi.decode(innerPayload, (bytes32));
      address vaultAddress = _deployVault(nexusId);
    }
  }
}
