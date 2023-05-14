//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IPacketGateway {
  function sendPacketTo(
    uint16 targetChainId,
    bytes memory packetBytes
  ) external payable;
}
