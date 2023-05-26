//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IVaultController} from '../../IVaultController.sol';

interface IVaultV1Controller is IVaultController {
  function setPrimaryVaultGateway(
    uint16 chainId,
    uint32 vaultId,
    address gatewayAddress
  ) external;

  function deployVault(
    uint16 chainId,
    uint32 vaultId,
    address gatewayAddress
  ) external;
}
