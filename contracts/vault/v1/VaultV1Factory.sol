//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {VaultV1} from './VaultV1.sol';

abstract contract VaultV1Factory {
  event VaultDeployed(bytes32 indexed nexusId, address indexed vaultAddress);

  bytes32 constant FACTORY_SALT = keccak256('VAULT_V1_FACTORY_SALT');

  mapping(bytes32 => int) private nexusVaultCounter;

  function _makeContractSalt(
    bytes32 nexusId,
    int vaultId
  ) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(FACTORY_SALT, nexusId, vaultId));
  }

  function _deployVault(bytes32 nexusId) internal returns (address) {
    int vaultId = nexusVaultCounter[nexusId]++;

    address vaultAddress = address(
      new VaultV1{salt: _makeContractSalt(nexusId, vaultId)}(nexusId)
    );

    emit VaultDeployed(nexusId, vaultAddress);
    return vaultAddress;
  }
}
