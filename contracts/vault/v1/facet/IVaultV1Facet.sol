// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IVaultV1Facet {
  function createVaultV1(
    uint16 chainId,
    uint32 vaultId,
    address gatewayAddress
  ) external;

  function setPrimaryVaultGatewayV1(
    uint16 chainId,
    uint32 vaultId,
    address gatewayAddress
  ) external;
}
