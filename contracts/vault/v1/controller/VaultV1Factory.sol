//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {BaseVaultV1Controller} from './BaseVaultV1Controller.sol';

import {VaultV1} from '../VaultV1.sol';

error VaultAtIdAlreadyExists(bytes32 nexusId, uint256 vaultId);

abstract contract VaultV1Factory is BaseVaultV1Controller {
  event VaultDeployed(
    bytes32 indexed nexusId,
    uint256 indexed vaultId,
    address indexed vaultAddress
  );

  bytes32 constant FACTORY_SALT = keccak256('VAULT_V1_FACTORY_SALT');

  function _makeContractSalt(
    bytes32 nexusId,
    uint256 vaultId
  ) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(FACTORY_SALT, nexusId, vaultId));
  }

  function _deployVault(
    bytes32 nexusId,
    uint256 vaultId,
    uint16 routingVersion
  ) internal {
    if (nexusVaults[nexusId].vaults[vaultId].addr != address(0)) {
      revert VaultAtIdAlreadyExists(nexusId, vaultId);
    }

    address vaultAddress = address(
      new VaultV1{salt: _makeContractSalt(nexusId, vaultId)}(nexusId)
    );

    nexusVaults[nexusId].vaults[vaultId] = VaultRecord({
      addr: vaultAddress,
      routingVersion: routingVersion
    });
    nexusVaults[nexusId].vaultIds.push(vaultId);

    emit VaultDeployed(nexusId, vaultId, vaultAddress);
  }
}
