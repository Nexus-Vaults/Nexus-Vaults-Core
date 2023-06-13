//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IVaultController} from '../../IVaultController.sol';
import {V1TokenTypes} from '../V1TokenTypes.sol';

interface IVaultV1Controller is IVaultController {
  function deployVault(
    uint16 destinationChainId,
    uint32 transmitUsingGatewayId,
    uint32 vaultId
  ) external payable;

  function addLocalAcceptedGateway(uint32 gatewayId) external;

  function addAcceptedGateway(
    uint16 destinationChainId,
    uint32 transmitUsingGatewayId,
    uint32 gatewayIdToAdd
  ) external payable;

  function sendPayment(
    uint16 destinationChainId,
    uint32 transmitUsingGatewayId,
    uint32 vaultId,
    V1TokenTypes tokenType,
    string calldata tokenIdentifier,
    string calldata target,
    uint256 amount
  ) external payable;

  function bridgeOut(
    uint16 targetChainId,
    uint32 transmitUsingGatewayId,
    uint32 vaultId,
    V1TokenTypes tokenType,
    string memory tokenIdentifier,
    uint32 destinationGatewayId,
    uint16 destinationChainId,
    string memory target,
    uint256 amount
  ) external payable;
}
