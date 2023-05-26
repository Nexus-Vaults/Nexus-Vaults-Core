//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

abstract contract BaseNexusGateway {
  function _handlePacket(
    uint16 sourceChainId,
    bytes memory message
  ) internal virtual;
}
