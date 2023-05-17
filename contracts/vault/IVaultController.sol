//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IVaultController {
  function handlePacket(
    uint16 senderChainId,
    bytes calldata payload
  ) external payable;
}
