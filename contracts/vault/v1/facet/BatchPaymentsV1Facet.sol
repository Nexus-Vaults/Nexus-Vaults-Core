// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IBatchPaymentsV1Facet} from './IBatchPaymentsV1Facet.sol';
import {V1ChainBatchPayment} from '../types/V1ChainBatchPayment.sol';
import {IDiamondFacet} from '../../../diamond/IDiamondFacet.sol';
import {IVaultV1Controller} from '../controller/IVaultV1Controller.sol';
import {LibDiamond} from '../../../diamond/LibDiamond.sol';

error MustBeDelegateCall();
error MustBeContractOwner();

contract BatchPaymentsV1Facet is IDiamondFacet, IBatchPaymentsV1Facet {
  IVaultV1Controller private immutable vaultController;
  address private immutable self;

  constructor(address _vaultController) {
    vaultController = IVaultV1Controller(_vaultController);
    self = address(this);
  }

  function getSelectors() external pure returns (bytes4[] memory) {
    bytes4[] memory selectors = new bytes4[](1);

    selectors[0] = this.batchSendPayment.selector;

    return selectors;
  }

  function getSupportedInterfaceIds()
    external
    pure
    returns (bytes4[] memory)
  {
    return new bytes4[](0);
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

  function batchSendPayment(
    V1ChainBatchPayment[] calldata batchPayments
  ) external payable {
    vaultController.batchSendPayment{value: msg.value}(batchPayments);
  }
}
