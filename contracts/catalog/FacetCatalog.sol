//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IFacetCatalog} from './IFacetCatalog.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

error FacetNotAvailable();
error FeeTransferFailed();

//ToDo: Make ERC1155
contract FacetCatalog is IFacetCatalog, Ownable {
  struct FacetOffering {
    bool available;
    uint256 feeAmount;
    mapping(address => bool) hasBought;
  }

  event FacetPurchased(
    address indexed nexus,
    address indexed facet,
    address token,
    uint256 amount
  );

  IERC20 public feeToken;
  mapping(address => FacetOffering) public offerings;

  constructor(IERC20 _feeToken, address treasuryAddress) {
    _transferOwnership(treasuryAddress);
    feeToken = _feeToken;
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
      !feeToken.transferFrom(
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
      address(feeToken),
      offerings[facetAddress].feeAmount
    );
  }
}
