//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IVaultV1Controller} from './IVaultV1Controller.sol';
import {V1PacketTypes} from '../types/V1PacketTypes.sol';
import {V1TokenTypes} from '../types/V1TokenTypes.sol';
import {V1SendChainBatch} from '../types/send/V1SendChainBatch.sol';
import {V1SendTokenBatch} from '../types/send/V1SendTokenBatch.sol';
import {INexus} from '../../../nexus/INexus.sol';
import {BaseVaultV1Controller} from './BaseVaultV1Controller.sol';
import {IFacetCatalog} from '../../../catalog/IFacetCatalog.sol';
import {VaultV1Facet} from '../facet/VaultV1Facet.sol';
import {BatchPaymentsV1Facet} from '../facet/BatchPaymentsV1Facet.sol';
import {IOUTokenRecord} from './modules/IOUTokenModule.sol';
import {IDeployer} from '../../../deployer/IDeployer.sol';

import {VaultFactoryModule} from './modules/VaultFactoryModule.sol';
import {GatewayAdapterModule} from './modules/GatewayAdapterModule.sol';
import {IOUTokenModule} from './modules/IOUTokenModule.sol';
import {InspectorModule} from './modules/InspectorModule.sol';

import {StringToAddress, AddressToString} from '../../../utils/StringAddressUtils.sol';

import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

error UnsupportedPacket(V1PacketTypes packetType);

contract VaultV1Controller is
  IVaultV1Controller,
  Ownable,
  BaseVaultV1Controller,
  GatewayAdapterModule,
  VaultFactoryModule,
  IOUTokenModule,
  InspectorModule
{
  using StringToAddress for string;
  using AddressToString for address;

  constructor()
    BaseVaultV1Controller(
      _decodeCurrentChainIdParam(),
      _decodeFacetCatalogParam(),
      address(new VaultV1Facet(address(this))),
      address(new BatchPaymentsV1Facet(address(this)))
    )
  {
    IDeployer deployer = IDeployer(msg.sender);
    bytes memory args = deployer.getCurrentDeploymentArgs();

    (, , address _owner) = abi.decode(
      args,
      (uint16, IFacetCatalog, address)
    );

    _transferOwnership(_owner);
  }

  function withdraw() external onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
  }

  function _decodeFacetCatalogParam()
    internal
    view
    returns (IFacetCatalog)
  {
    IDeployer deployer = IDeployer(msg.sender);
    bytes memory args = deployer.getCurrentDeploymentArgs();
    (, IFacetCatalog _facetCatalog, ) = abi.decode(
      args,
      (uint16, IFacetCatalog, address)
    );
    return _facetCatalog;
  }

  function _decodeCurrentChainIdParam() internal view returns (uint16) {
    IDeployer deployer = IDeployer(msg.sender);
    bytes memory args = deployer.getCurrentDeploymentArgs();
    (uint16 _currentChainId, , ) = abi.decode(
      args,
      (uint16, IFacetCatalog, address)
    );
    return _currentChainId;
  }

  function deployVault(
    uint16 destinationChainId,
    uint32 transmitUsingGatewayId,
    uint32 vaultId
  ) external payable onlyFacetOwners {
    bytes32 nexusId = _makeNexusId(msg.sender);
    bytes memory innerPayload = abi.encode(vaultId);

    _sendPacket(
      destinationChainId,
      V1PacketTypes.CreateVault,
      nexusId,
      innerPayload,
      transmitUsingGatewayId,
      msg.value
    );
  }

  function addLocalAcceptedGateway(
    uint32 gatewayId
  ) external onlyFacetOwners {
    bytes32 nexusId = _makeNexusId(msg.sender);

    if (!nexusVaults[nexusId].isInitialized) {
      _initializeNexus(nexusId, gatewayId);
    } else {
      _addAcceptedGatewayToNexus(nexusId, gatewayId);
    }
  }

  function addAcceptedGateway(
    uint16 destinationChainId,
    uint32 transmitUsingGatewayId,
    uint32 gatewayIdToAdd
  ) external payable onlyFacetOwners {
    bytes32 nexusId = _makeNexusId(msg.sender);
    bytes memory innerPayload = abi.encode(gatewayIdToAdd);

    _sendPacket(
      destinationChainId,
      V1PacketTypes.AddAcceptedGateway,
      nexusId,
      innerPayload,
      transmitUsingGatewayId,
      msg.value
    );
  }

  function sendPayment(
    uint16 destinationChainId,
    uint32 transmitUsingGatewayId,
    uint32 vaultId,
    V1TokenTypes tokenType,
    string calldata tokenIdentifier,
    string calldata target,
    uint256 amount
  ) external payable onlyFacetOwners {
    bytes32 nexusId = _makeNexusId(msg.sender);
    bytes memory innerPayload = abi.encode(
      vaultId,
      tokenType,
      tokenIdentifier,
      target,
      amount
    );

    _sendPacket(
      destinationChainId,
      V1PacketTypes.SendPayment,
      nexusId,
      innerPayload,
      transmitUsingGatewayId,
      msg.value
    );
  }

  function batchSend(
    V1SendChainBatch[] calldata batches
  ) external payable onlyBatchFacetOwners {
    bytes32 nexusId = _makeNexusId(msg.sender);

    for (uint i = 0; i < batches.length; i++) {
      V1SendChainBatch calldata batch = batches[i];

      bytes memory payload = abi.encode(batch.vaultPayments);

      _sendPacket(
        batch.destinationChainId,
        V1PacketTypes.BatchSend,
        nexusId,
        payload,
        batch.transmitUsingGatewayId,
        batch.gasFeeAmount
      );
    }
  }

  function redeemPayment(
    address iouTokenAddress,
    string calldata target,
    uint256 amount
  ) external payable {
    IOUTokenRecord storage tokenRecord = tokenToRecord[iouTokenAddress];

    _burnIOU(
      tokenRecord.vaultChainId,
      tokenRecord.gatewayId,
      tokenRecord.nexusId,
      tokenRecord.vaultId,
      tokenRecord.tokenType,
      tokenRecord.tokenIdentifier,
      msg.sender,
      amount
    );

    bytes memory innerPayload = abi.encode(
      tokenRecord.vaultId,
      tokenRecord.tokenType,
      tokenRecord.tokenIdentifier,
      target,
      amount
    );

    _sendPacket(
      tokenRecord.vaultChainId,
      V1PacketTypes.RedeemPayment,
      tokenRecord.nexusId,
      innerPayload,
      tokenRecord.gatewayId,
      msg.value
    );
  }

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
  ) external payable onlyFacetOwners {
    bytes32 nexusId = _makeNexusId(msg.sender);
    bytes memory innerPayload = abi.encode(
      vaultId,
      tokenType,
      tokenIdentifier,
      destinationGatewayId,
      destinationChainId,
      target,
      amount
    );

    _sendPacket(
      targetChainId,
      V1PacketTypes.BridgeOut,
      nexusId,
      innerPayload,
      transmitUsingGatewayId,
      msg.value
    );
  }

  function _handlePacket(
    uint16 senderChainId,
    V1PacketTypes packetType,
    bytes32 nexusId,
    bytes memory payload,
    uint32 gatewayId
  ) internal override {
    if (packetType == V1PacketTypes.CreateVault) {
      _handleDeployVault(nexusId, payload);
      return;
    }
    if (packetType == V1PacketTypes.AddAcceptedGateway) {
      _handleAddAcceptedGateway(nexusId, payload);
      return;
    }
    if (packetType == V1PacketTypes.SendPayment) {
      _handleSendPayment(nexusId, payload);
      return;
    }
    if (packetType == V1PacketTypes.BatchSend) {
      _handleBatchSend(nexusId, gatewayId, payload);
      return;
    }
    if (packetType == V1PacketTypes.RedeemPayment) {
      _handleRedeemPayment(nexusId, gatewayId, payload);
      return;
    }
    if (packetType == V1PacketTypes.BridgeOut) {
      _handleBridgeOut(nexusId, payload);
      return;
    }
    if (packetType == V1PacketTypes.MintIOUTokens) {
      _handleMintIOUTokens(senderChainId, nexusId, gatewayId, payload);
      return;
    }

    revert UnsupportedPacket(packetType);
  }

  function _handleDeployVault(
    bytes32 nexusId,
    bytes memory payload
  ) internal {
    uint32 vaultId = abi.decode(payload, (uint32));

    _deployVault(nexusId, vaultId);
  }

  function _handleAddAcceptedGateway(
    bytes32 nexusId,
    bytes memory payload
  ) internal {
    uint32 gatewayIdToAdd = abi.decode(payload, (uint32));
    _addAcceptedGatewayToNexus(nexusId, gatewayIdToAdd);
  }

  function _handleSendPayment(
    bytes32 nexusId,
    bytes memory payload
  ) internal {
    (
      uint32 vaultId,
      V1TokenTypes tokenType,
      string memory tokenIdentifier,
      string memory target,
      uint256 amount
    ) = abi.decode(
        payload,
        (uint32, V1TokenTypes, string, string, uint256)
      );

    _enforceMinimumAvailableBalance(
      nexusId,
      vaultId,
      tokenType,
      tokenIdentifier,
      amount
    );
    nexusVaults[nexusId].vaults[vaultId].vault.sendTokens(
      tokenType,
      tokenIdentifier,
      payable(target.toAddress()),
      amount
    );
  }

  function _handleBatchSend(
    bytes32 nexusId,
    uint32 gatewayId,
    bytes memory payload
  ) internal {
    V1SendTokenBatch[] memory batches = abi.decode(
      payload,
      (V1SendTokenBatch[])
    );

    for (uint batchIndex = 0; batchIndex < batches.length; batchIndex++) {
      V1SendTokenBatch memory tokenBatch = batches[batchIndex];

      if (tokenBatch.tokenChainId == currentChainId) {
        uint256 bridgedBalance = nexusVaults[nexusId]
        .vaults[tokenBatch.vaultId]
        .tokens[tokenBatch.tokenType][tokenBatch.tokenIdentifier]
          .bridgedBalance;

        bool success = nexusVaults[nexusId]
          .vaults[tokenBatch.vaultId]
          .vault
          .batchSendTokens(
            tokenBatch.tokenType,
            tokenBatch.tokenIdentifier,
            tokenBatch.payments,
            bridgedBalance
          );

        if (!success) {
          _revertWithAvailableBalanceTooLow(nexusId, tokenBatch.vaultId);
        }
      } else {
        _batchMintIOU(
          tokenBatch.tokenChainId,
          gatewayId,
          nexusId,
          tokenBatch.vaultId,
          tokenBatch.tokenType,
          tokenBatch.tokenIdentifier,
          tokenBatch.payments
        );
      }
    }
  }

  function _handleRedeemPayment(
    bytes32 nexusId,
    uint32 gatewayId,
    bytes memory payload
  ) internal {
    (
      uint32 vaultId,
      V1TokenTypes tokenType,
      string memory tokenIdentifier,
      string memory target,
      uint256 amount
    ) = abi.decode(
        payload,
        (uint32, V1TokenTypes, string, string, uint256)
      );

    _enforceMinimumGatewayBalance(
      nexusId,
      vaultId,
      tokenType,
      tokenIdentifier,
      amount,
      gatewayId
    );
    _decrementBridgedBalance(
      nexusId,
      vaultId,
      tokenType,
      tokenIdentifier,
      amount,
      gatewayId
    );
    nexusVaults[nexusId].vaults[vaultId].vault.sendTokens(
      tokenType,
      tokenIdentifier,
      payable(target.toAddress()),
      amount
    );
  }

  function _handleBridgeOut(
    bytes32 nexusId,
    bytes memory payload
  ) internal {
    (
      uint32 vaultId,
      V1TokenTypes tokenType,
      string memory tokenIdentifier,
      uint32 destinationGatewayId,
      uint16 destinationChainId,
      string memory target,
      uint256 amount
    ) = abi.decode(
        payload,
        (uint32, V1TokenTypes, string, uint32, uint16, string, uint256)
      );

    _enforceAcceptedGateway(nexusId, destinationGatewayId);
    _enforceMinimumAvailableBalance(
      nexusId,
      vaultId,
      tokenType,
      tokenIdentifier,
      amount
    );
    _incrementBridgedBalance(
      nexusId,
      vaultId,
      tokenType,
      tokenIdentifier,
      amount,
      destinationGatewayId
    );
    _sendPacket(
      destinationChainId,
      V1PacketTypes.MintIOUTokens,
      nexusId,
      abi.encode(vaultId, tokenType, tokenIdentifier, target, amount),
      destinationGatewayId,
      msg.value
    );
  }

  function _handleMintIOUTokens(
    uint16 senderChainId,
    bytes32 nexusId,
    uint32 gatewayId,
    bytes memory payload
  ) internal {
    (
      uint32 vaultId,
      V1TokenTypes tokenType,
      string memory tokenIdentifier,
      string memory target,
      uint256 amount
    ) = abi.decode(
        payload,
        (uint32, V1TokenTypes, string, string, uint256)
      );

    _mintIOU(
      senderChainId,
      gatewayId,
      nexusId,
      vaultId,
      tokenType,
      tokenIdentifier,
      target.toAddress(),
      amount
    );
  }

  function _makeNexusId(
    address nexusAddress
  ) internal view returns (bytes32) {
    return keccak256(abi.encodePacked(currentChainId, nexusAddress));
  }
}
