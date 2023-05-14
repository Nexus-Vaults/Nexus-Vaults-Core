//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface INexusGateway {
  function relayPacket(
    uint16 targetChainId,
    uint8 messageType,
    bytes memory innerPacketBytes
  ) external payable;

  function handlePacket(
    uint16 senderChainId,
    bytes memory packetBytes
  ) external payable;
}
