//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {BaseVaultV1Controller} from '../BaseVaultV1Controller.sol';
import {VaultV1} from '../../VaultV1.sol';

error VaultDoesNotExist(bytes32 nexusId, uint256 vaultId);

struct VaultInfo {
  uint32 vaultId;
  VaultV1 vault;
}

abstract contract InspectorModule is BaseVaultV1Controller {
  function listVaults(
    bytes32 nexusId
  ) external view returns (VaultInfo[] memory) {
    NexusRecord storage nexus = nexusVaults[nexusId];
    VaultInfo[] memory vaults = new VaultInfo[](nexus.vaultIds.length);

    for (uint256 i = 0; i < nexus.vaultIds.length; i++) {
      vaults[i] = VaultInfo({
        vaultId: nexus.vaultIds[i],
        vault: nexus.vaults[nexus.vaultIds[i]].vault
      });
    }

    return vaults;
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
}
