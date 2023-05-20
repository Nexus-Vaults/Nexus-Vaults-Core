//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

error VaultDoesNotExist(bytes32 nexusId, uint256 vaultId);

abstract contract BaseVaultV1Controller {
  struct NexusRecord {
    mapping(uint256 => VaultRecord) vaults;
    uint32[] vaultIds;
  }
  struct VaultRecord {
    address addr;
    uint16 routingVersion;
  }

  event VaultRoutingVersionUpdated(
    bytes32 indexed nexusId,
    uint32 indexed vaultId,
    uint16 previousRoutingVersion,
    uint16 currentRoutingVersion
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
  ) external view returns (VaultRecord memory) {
    VaultRecord memory vault = nexusVaults[nexusId].vaults[vaultId];

    if (vault.addr == address(0)) {
      revert VaultDoesNotExist(nexusId, vaultId);
    }

    return vault;
  }

  function listVaults(
    bytes32 nexusId
  ) external view returns (VaultRecord[] memory) {
    NexusRecord storage nexus = nexusVaults[nexusId];
    VaultRecord[] memory vaults = new VaultRecord[](nexus.vaultIds.length);

    for (uint256 i = 0; i < nexus.vaultIds.length; i++) {
      vaults[i] = nexus.vaults[nexus.vaultIds[i]];
    }

    return vaults;
  }

  function _setVaultRoutingVersion(
    bytes32 nexusId,
    uint32 vaultId,
    uint16 routingVersion
  ) internal {
    emit VaultRoutingVersionUpdated(
      nexusId,
      vaultId,
      nexusVaults[nexusId].vaults[vaultId].routingVersion,
      routingVersion
    );

    nexusVaults[nexusId].vaults[vaultId].routingVersion = routingVersion;
  }
}
