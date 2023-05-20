//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {VaultV1} from '../VaultV1.sol';

error VaultDoesNotExist(bytes32 nexusId, uint256 vaultId);
error VaultAtIdAlreadyExists(bytes32 nexusId, uint256 vaultId);

abstract contract VaultV1Factory {
  event VaultDeployed(
    bytes32 indexed nexusId,
    uint256 indexed vaultId,
    address indexed vaultAddress
  );

  struct NexusVaults {
    mapping(uint256 => address) vaultAddresses;
    uint256[] vaultIds;
  }

  bytes32 constant FACTORY_SALT = keccak256('VAULT_V1_FACTORY_SALT');

  mapping(bytes32 => NexusVaults) private nexusVaults;

  function getVaultIds(
    bytes32 nexusId
  ) external view returns (uint256[] memory) {
    return nexusVaults[nexusId].vaultIds;
  }

  function getVaultAddress(
    bytes32 nexusId,
    uint256 vaultId
  ) external view returns (address) {
    address vaultAddress = nexusVaults[nexusId].vaultAddresses[vaultId];

    if (vaultAddress == address(0)) {
      revert VaultDoesNotExist(nexusId, vaultId);
    }

    return vaultAddress;
  }

  function listVaultAddresses(
    bytes32 nexusId
  ) external view returns (address[] memory) {
    NexusVaults storage vaults = nexusVaults[nexusId];
    address[] memory vaultAddresses = new address[](vaults.vaultIds.length);

    for (uint256 i = 0; i < vaults.vaultIds.length; i++) {
      vaultAddresses[i] = vaults.vaultAddresses[vaults.vaultIds[i]];
    }

    return vaultAddresses;
  }

  function _makeContractSalt(
    bytes32 nexusId,
    uint256 vaultId
  ) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(FACTORY_SALT, nexusId, vaultId));
  }

  function _deployVault(bytes32 nexusId, uint256 vaultId) internal {
    if (nexusVaults[nexusId].vaultAddresses[vaultId] != address(0)) {
      revert VaultAtIdAlreadyExists(nexusId, vaultId);
    }

    address vaultAddress = address(
      new VaultV1{salt: _makeContractSalt(nexusId, vaultId)}(nexusId)
    );

    nexusVaults[nexusId].vaultAddresses[vaultId] = vaultAddress;
    nexusVaults[nexusId].vaultIds.push(vaultId);

    emit VaultDeployed(nexusId, vaultId, vaultAddress);
  }
}
