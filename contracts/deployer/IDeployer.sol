//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IDeployer {
  function getCurrentDeploymentArgs() external view returns (bytes memory);
}
