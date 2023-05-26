//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import '../../../diamond/IDiamondFacet.sol';
import '../controller/IVaultV1Controller.sol';
import '../../../diamond/LibDiamond.sol';
import './IVaultV1Facet.sol';

error MustBeDelegateCall();
error MustBeContractOwner();

contract VaultV1Facet is IDiamondFacet, IVaultV1Facet {
  bytes32 constant VAULTV1_STORAGE_POSITION = keccak256('diamond.standard.vaultv1.storage');

  struct VaultV1Storage {
    mapping(address => mapping(bytes32 => bool)) permissions;
  }

  IVaultV1Controller private immutable vaultController;
  address private immutable self;

  constructor(IVaultV1Controller _vaultController) {
    vaultController = _vaultController;
    self = address(this);
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

  function vaultV1Storage() internal pure returns (VaultV1Storage storage ds) {
    bytes32 position = VAULTV1_STORAGE_POSITION;
    assembly {
      ds.slot := position
    }
  }

  function createVaultV1(
    uint16 chainId,
    uint32 vaultId,
    address transmitUsing
  ) external onlyDelegateCall onlyDiamondOwner {
    vaultController.deployVault(chainId, vaultId, transmitUsing);
  }

  function addAcceptedGateway(
    uint16 chainId,
    address gatewayToAdd,
    address transmitUsing
  ) external onlyDelegateCall onlyDiamondOwner {
    vaultController.addAcceptedGateway(chainId, gatewayToAdd, transmitUsing);
  }

  function getSelectors() external pure returns (bytes4[] memory) {
    bytes4[] memory selectors = new bytes4[](2);

    selectors[0] = this.createVaultV1.selector;
    selectors[1] = this.addAcceptedGateway.selector;

    return selectors;
  }
}
