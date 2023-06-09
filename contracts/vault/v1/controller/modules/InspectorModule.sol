//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {BaseVaultV1Controller} from '../BaseVaultV1Controller.sol';
import {VaultV1} from '../../VaultV1.sol';
import {V1TokenInfo} from '../../types/V1TokenInfo.sol';

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

  function aggregateBalances(
    bytes32 nexusId,
    V1TokenInfo[] memory tokens
  ) external view returns (uint256[] memory) {
    uint256[] memory balances = new uint256[](tokens.length);

    NexusRecord storage nexus = nexusVaults[nexusId];

    for (uint tokenIndex = 0; tokenIndex < tokens.length; tokenIndex++) {
      for (
        uint256 vaultIndex = 0;
        vaultIndex < nexus.vaultIds.length;
        vaultIndex++
      ) {
        balances[tokenIndex] += nexus
          .vaults[nexus.vaultIds[vaultIndex]]
          .vault
          .getBalance(
            tokens[tokenIndex].tokenType,
            tokens[tokenIndex].tokenIdentifier
          );
      }
    }

    return balances;
  }

  function listAcceptedGateways(
    bytes32 nexusId
  ) external view returns (uint32[] memory) {
    NexusRecord storage nexus = nexusVaults[nexusId];
    uint256 acceptedGatewayCount = 0;

    for (uint32 i = 1; i <= gatewayCount; i++) {
      if (!nexus.acceptedGateways[i]) {
        continue;
      }

      acceptedGatewayCount++;
    }

    uint32[] memory gatewayIds = new uint32[](acceptedGatewayCount);
    acceptedGatewayCount = 0;

    for (uint32 i = 1; i <= gatewayCount; i++) {
      if (!nexus.acceptedGateways[i]) {
        continue;
      }

      gatewayIds[acceptedGatewayCount] = i;
      acceptedGatewayCount++;
    }

    return gatewayIds;
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
