//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract VaultV1 {
  bytes32 immutable NexusId;

  constructor(bytes32 nexusId) {
    NexusId = nexusId;
  }
}
