//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IDeployer} from './IDeployer.sol';

contract Deployer {
  error NoArgsSet();
  error NoDeploymentFound();

  mapping(bytes32 => address) private contractAddresses;

  bytes private currentDeploymentArgs;

  function getDeployedAddress(
    bytes memory bytecode
  ) external view returns (address) {
    bytes32 byteCodeHash = keccak256(bytecode);

    if (contractAddresses[byteCodeHash] == address(0)) {
      revert NoDeploymentFound();
    }

    return contractAddresses[byteCodeHash];
  }

  function deployContract(
    bytes memory bytecode,
    bytes calldata args
  ) external payable {
    currentDeploymentArgs = args;

    bytes32 byteCodeHash = keccak256(bytecode);
    uint256 salt = uint256(byteCodeHash);
    address contractAddress;

    assembly {
      contractAddress := create2(
        callvalue(),
        add(bytecode, 0x20),
        mload(bytecode),
        salt
      )

      if iszero(extcodesize(contractAddress)) {
        revert(0, 0)
      }
    }

    contractAddresses[byteCodeHash] = contractAddress;
    delete currentDeploymentArgs;
  }

  function getCurrentDeploymentArgs()
    external
    view
    returns (bytes memory)
  {
    if (currentDeploymentArgs.length == 0) {
      revert NoArgsSet();
    }

    return currentDeploymentArgs;
  }
}
