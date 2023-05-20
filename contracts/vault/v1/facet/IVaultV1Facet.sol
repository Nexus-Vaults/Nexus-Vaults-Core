// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IVaultV1Facet {
  function createVaultV1(
    uint16 chainId,
    uint32 vaultId,
    uint16 routingVersion
  ) external;

  function setVaultRoutingVersionV1(
    uint16 chainId,
    uint32 vaultId,
    uint16 routingVersion
  ) external;
}
