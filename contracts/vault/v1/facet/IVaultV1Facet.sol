// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {V1TokenTypes} from '../types/V1TokenTypes.sol';

interface IVaultV1Facet {
  function createVaultV1(
    uint16 destinationChainId,
    uint32 transmitUsingGatewayId,
    uint32 vaultId
  ) external payable;

  function addLocalAcceptedGatewayV1(uint32 gatewayId) external;

  function addAcceptedGatewayV1(
    uint16 destinationChainId,
    uint32 transmitUsingGatewayId,
    uint32 gatewayIdToAdd
  ) external payable;

  function sendPaymentV1(
    uint16 destinationChainId,
    uint32 transmitUsingGatewayId,
    uint32 vaultId,
    V1TokenTypes tokenType,
    string calldata tokenIdentifier,
    string calldata target,
    uint256 amount
  ) external payable;

  function bridgeOutV1(
    uint16 targetChainId,
    uint32 transmitUsingGatewayId,
    uint32 vaultId,
    V1TokenTypes tokenType,
    string memory tokenIdentifier,
    uint32 targetGatewayId,
    uint16 destinationChainId,
    string memory target,
    uint256 amount
  ) external payable;
}
