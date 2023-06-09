//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IDiamondFacet} from '../../../diamond/IDiamondFacet.sol';
import {IVaultV1Controller} from '../controller/IVaultV1Controller.sol';
import {LibDiamond} from '../../../diamond/LibDiamond.sol';
import {IVaultV1Facet} from './IVaultV1Facet.sol';
import {V1TokenTypes} from '../types/V1TokenTypes.sol';

error MustBeDelegateCall();
error MustBeContractOwner();

contract VaultV1Facet is IDiamondFacet, IVaultV1Facet {
  IVaultV1Controller private immutable vaultController;
  address private immutable self;

  constructor(address _vaultController) {
    vaultController = IVaultV1Controller(_vaultController);
    self = address(this);
  }

  function getSelectors() external pure returns (bytes4[] memory) {
    bytes4[] memory selectors = new bytes4[](5);

    selectors[0] = this.createVaultV1.selector;
    selectors[1] = this.addLocalAcceptedGatewayV1.selector;
    selectors[2] = this.addAcceptedGatewayV1.selector;
    selectors[3] = this.sendPaymentV1.selector;
    selectors[4] = this.bridgeOutV1.selector;

    return selectors;
  }

  function getSupportedInterfaceIds()
    external
    pure
    returns (bytes4[] memory)
  {
    bytes4[] memory interfaceIds = new bytes4[](5);

    interfaceIds[0] = type(IVaultV1Facet).interfaceId;

    return interfaceIds;
  }

  modifier onlyDelegateCall() {
    if (address(this) == self) {
      revert MustBeDelegateCall();
    }
    _;
  }

  modifier onlyDiamondOwner() {
    if (msg.sender != LibDiamond.diamondStorage().contractOwner) {
      revert MustBeContractOwner();
    }
    _;
  }

  function createVaultV1(
    uint16 destinationChainId,
    uint32 transmitUsingGatewayId,
    uint32 vaultId
  ) external payable onlyDelegateCall onlyDiamondOwner {
    vaultController.deployVault{value: msg.value}(
      destinationChainId,
      transmitUsingGatewayId,
      vaultId
    );
  }

  function addLocalAcceptedGatewayV1(
    uint32 gatewayId
  ) external onlyDelegateCall onlyDiamondOwner {
    vaultController.addLocalAcceptedGateway(gatewayId);
  }

  function addAcceptedGatewayV1(
    uint16 destinationChainId,
    uint32 transmitUsingGatewayId,
    uint32 gatewayIdToAdd
  ) external payable onlyDelegateCall onlyDiamondOwner {
    vaultController.addAcceptedGateway{value: msg.value}(
      destinationChainId,
      transmitUsingGatewayId,
      gatewayIdToAdd
    );
  }

  function sendPaymentV1(
    uint16 destinationChainId,
    uint32 transmitUsingGatewayId,
    uint32 vaultId,
    V1TokenTypes tokenType,
    string calldata tokenIdentifier,
    string calldata target,
    uint256 amount
  ) external payable onlyDelegateCall onlyDiamondOwner {
    vaultController.sendPayment{value: msg.value}(
      destinationChainId,
      transmitUsingGatewayId,
      vaultId,
      tokenType,
      tokenIdentifier,
      target,
      amount
    );
  }

  function bridgeOutV1(
    uint16 targetChainId,
    uint32 transmitUsingGatewayId,
    uint32 vaultId,
    V1TokenTypes tokenType,
    string memory tokenIdentifier,
    uint32 destinationGatewayId,
    uint16 destinationChainId,
    string memory target,
    uint256 amount
  ) external payable onlyDelegateCall onlyDiamondOwner {
    vaultController.bridgeOut{value: msg.value}(
      targetChainId,
      transmitUsingGatewayId,
      vaultId,
      tokenType,
      tokenIdentifier,
      destinationGatewayId,
      destinationChainId,
      target,
      amount
    );
  }
}
