// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IVaultV1Facet {
  function createVaultV1(
    uint16 chainId,
    uint32 vaultId,
    address transmitUsing
  ) external;

  function addAcceptedGateway(
    uint16 chainId,
    address gatewayToAdd,
    address transmitUsing
  ) external;
}
