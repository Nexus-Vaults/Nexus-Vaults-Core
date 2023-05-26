//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {BaseVaultV1Controller} from '../BaseVaultV1Controller.sol';
import {VaultV1} from "../../VaultV1.sol";

error VaultDoesNotExist(bytes32 nexusId, uint256 vaultId);

abstract contract InspectorModule is BaseVaultV1Controller {
    function getVaultIds(
    bytes32 nexusId
  ) external view returns (uint32[] memory) {
    return nexusVaults[nexusId].vaultIds;
  }

  function getVault(
    bytes32 nexusId,
    uint32 vaultId
  ) external view returns (VaultV1 vault) {
    VaultRecord storage vaultRecord = nexusVaults[nexusId].vaults[vaultId];

    if (!vaultRecord.isDefined) {
      revert VaultDoesNotExist(nexusId, vaultId);
    }

    return vaultRecord.vault;
  }

  function listVaults(
    bytes32 nexusId
  ) external view returns (VaultV1[] memory) {
    NexusRecord storage nexus = nexusVaults[nexusId];
    VaultV1[] memory vaults = new VaultV1[](nexus.vaultIds.length);

    for (uint256 i = 0; i < nexus.vaultIds.length; i++) {
      vaults[i] = nexus.vaults[nexus.vaultIds[i]].vault;
    }

    return vaults;
  }
}