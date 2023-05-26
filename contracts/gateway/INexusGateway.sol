//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface INexusGateway {
  function isReady() external view returns (bool isReady);

  function sendPacketTo(
    uint16 chainId,
    bytes memory payload
  ) external payable;
}
