//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IFacetCatalog} from './IFacetCatalog.sol';
import {IDeployer} from '../deployer/IDeployer.sol';
import {SimpleERC1155} from './SimpleERC1155.sol';

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';

error FacetNotAvailable();
error FacetAlreadyAvailable();
error FeeTransferFailed();

//ToDo: Make ERC1155
contract FacetCatalog is SimpleERC1155, IFacetCatalog, Ownable {
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

  constructor() SimpleERC1155('') {
    IDeployer deployer = IDeployer(msg.sender);
    bytes memory args = deployer.getCurrentDeploymentArgs();
    address _treasuryAddress = abi.decode(args, (address));

    _transferOwnership(_treasuryAddress);
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
    _mint(
      msg.sender,
      uint256(keccak256(abi.encodePacked(facetAddress))),
      1,
      ''
    );

    emit FacetPurchased(
      msg.sender,
      facetAddress,
      offerings[facetAddress].feeToken,
      offerings[facetAddress].feeAmount
    );
  }

  function setMetadataURI(string memory metadataURI) external onlyOwner {
    _setURI(metadataURI);
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
