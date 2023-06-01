//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import '../../../diamond/IDiamondFacet.sol';
import '../controller/IVaultV1Controller.sol';
import '../../../diamond/LibDiamond.sol';
import './IVaultV1Facet.sol';

error MustBeDelegateCall();
error MustBeContractOwner();

contract VaultV1Facet is IDiamondFacet, IVaultV1Facet {
  bytes32 constant VAULTV1_STORAGE_POSITION =
    keccak256('diamond.standard.vaultv1.storage');

  struct VaultV1Storage {
    mapping(address => mapping(bytes32 => bool)) permissions;
  }

  IVaultV1Controller private immutable vaultController;
  address private immutable self;

  constructor(address _vaultController) {
    vaultController = IVaultV1Controller(_vaultController);
    self = address(this);
  }

  function getSelectors() external pure returns (bytes4[] memory) {
    bytes4[] memory selectors = new bytes4[](4);

    selectors[0] = this.createVaultV1.selector;
    selectors[1] = this.addAcceptedGateway.selector;
    selectors[2] = this.sendPayment.selector;
    selectors[3] = this.bridgeOut.selector;

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

  function vaultV1Storage()
    internal
    pure
    returns (VaultV1Storage storage ds)
  {
    bytes32 position = VAULTV1_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
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

  function addLocalAcceptedGateway(
    uint32 gatewayId
  ) external onlyDelegateCall onlyDiamondOwner {
    vaultController.addLocalAcceptedGateway(gatewayId);
  }

  function addAcceptedGateway(
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

  function sendPayment(
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

  function bridgeOut(
    uint16 targetChainId,
    uint32 transmitUsingGatewayId,
    uint32 vaultId,
    V1TokenTypes tokenType,
    string calldata tokenIdentifier,
    uint16 destinationChainId,
    address destinationGatewayAddress,
    string memory target,
    uint256 amount
  ) external payable onlyDelegateCall onlyDiamondOwner {
    vaultController.bridgeOut{value: msg.value}(
      targetChainId,
      transmitUsingGatewayId,
      vaultId,
      tokenType,
      tokenIdentifier,
      destinationChainId,
      destinationGatewayAddress,
      target,
      amount
    );
  }
}
