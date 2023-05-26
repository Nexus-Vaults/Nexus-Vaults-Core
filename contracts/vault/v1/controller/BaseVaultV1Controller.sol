//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import '../VaultV1.sol';

error VaultDoesNotExist(bytes32 nexusId, uint256 vaultId);

abstract contract BaseVaultV1Controller {
  struct NexusRecord {
    mapping(uint256 => VaultRecord) vaults;
    mapping(address => bool) acceptedGateways;
    uint32[] vaultIds;
  }
  struct VaultRecord {
    bool isDefined;
    VaultV1 vault;
  }

  event NexusAddAcceptedGateway(
    bytes32 indexed nexusId,
    address indexed gateway
  );

  mapping(bytes32 => NexusRecord) internal nexusVaults;

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

  function _enableNexusRoutingVersion(
    bytes32 nexusId,
    address gatewayAddress
  ) internal {
    emit NexusAddAcceptedGateway(nexusId, gatewayAddress);

    nexusVaults[nexusId].acceptedGateways[gatewayAddress] = true;
  }
}
