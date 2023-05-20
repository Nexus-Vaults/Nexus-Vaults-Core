//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IVaultController} from '../../IVaultController.sol';

interface IVaultV1Controller is IVaultController {
  function setVaultRoutingVersion(
    uint16 chainId,
    uint32 vaultId,
    uint16 routingVersion
  ) external;

  function deployVault(
    uint16 chainId,
    uint32 vaultId,
    uint16 routingVersion
  ) external;
}
