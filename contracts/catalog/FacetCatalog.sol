//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IFacetCatalog} from './IFacetCatalog.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

error FacetNotAvailable();
error FacetAlreadyAvailable();
error FeeTransferFailed();

//ToDo: Make ERC1155
contract FacetCatalog is IFacetCatalog, Ownable {
  struct FacetOffering {
    bool available;
    IERC20 feeToken;
    uint256 feeAmount;
    mapping(address => bool) hasBought;
  }

  event FacetOfferingAdded(
    address indexed facetAddress,
    IERC20 feeToken,
    uint256 feeAmount
  );
  event FacetOfferingFeeUpdated(
    address indexed facetAddress,
    IERC20 feeToken,
    uint256 feeAmount
  );
  event FacetOfferingRemoved(address indexed facetAddress);

  event FacetPurchased(
    address indexed nexus,
    address indexed facetAddress,
    IERC20 feeToken,
    uint256 feeAmount
  );

  mapping(address => FacetOffering) public offerings;

  constructor(address treasuryAddress) {
    _transferOwnership(treasuryAddress);
  }

  function hasPurchased(
    address user,
    address facetAddress
  ) external view returns (bool) {
    if (!offerings[facetAddress].available) {
      revert FacetNotAvailable();
    }

    return offerings[facetAddress].hasBought[user];
  }

  function purchaseFacet(address facetAddress) external {
    purchaseFacetFrom(msg.sender, facetAddress);
  }

  function purchaseFacetFrom(address payer, address facetAddress) public {
    if (!offerings[facetAddress].available) {
      revert FacetNotAvailable();
    }
    if (
      !offerings[facetAddress].feeToken.transferFrom(
        payer,
        owner(),
        offerings[facetAddress].feeAmount
      )
    ) {
      revert FeeTransferFailed();
    }

    offerings[facetAddress].hasBought[msg.sender] = true;
    emit FacetPurchased(
      msg.sender,
      facetAddress,
      offerings[facetAddress].feeToken,
      offerings[facetAddress].feeAmount
    );
  }

  function addOffering(
    address facetAddress,
    IERC20 feeToken,
    uint256 feeAmount
  ) external onlyOwner {
    if (offerings[facetAddress].available) {
      revert FacetAlreadyAvailable();
    }

    FacetOffering storage offering = offerings[facetAddress];

    offering.available = true;
    offering.feeToken = feeToken;
    offering.feeAmount = feeAmount;

    emit FacetOfferingAdded(facetAddress, feeToken, feeAmount);
  }

  function updateFee(
    address facetAddress,
    IERC20 feeToken,
    uint256 feeAmount
  ) external onlyOwner {
    if (!offerings[facetAddress].available) {
      revert FacetNotAvailable();
    }

    FacetOffering storage offering = offerings[facetAddress];

    offering.feeToken = feeToken;
    offering.feeAmount = feeAmount;

    emit FacetOfferingFeeUpdated(facetAddress, feeToken, feeAmount);
  }

  function removeOffering(address facetAddress) external onlyOwner {
    if (!offerings[facetAddress].available) {
      revert FacetNotAvailable();
    }

    offerings[facetAddress].available = false;

    emit FacetOfferingRemoved(facetAddress);
  }
}
