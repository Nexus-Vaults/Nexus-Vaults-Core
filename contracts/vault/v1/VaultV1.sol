//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {V1TokenTypes} from './types/V1TokenTypes.sol';
import {StringToAddress} from '../../utils/StringAddressUtils.sol';
import {V1TokenInfo} from './types/V1TokenInfo.sol';
import {V1TokenPayment} from './types/V1TokenPayment.sol';
import {V1Payment} from './types/V1Payment.sol';

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

error CallerMustBeVaultFactory(
  address factoryAddress,
  address callerAddress
);

error UnsupportedTokenType(V1TokenTypes tokenType);

contract VaultV1 {
  using StringToAddress for string;

  address public immutable VaultFactoryAddress;

  constructor() {
    VaultFactoryAddress = msg.sender;
  }

  modifier onlyFactory() {
    if (msg.sender != VaultFactoryAddress) {
      revert CallerMustBeVaultFactory(VaultFactoryAddress, msg.sender);
    }
    _;
  }

  function batchSendTokens(
    V1TokenPayment calldata tokenPayment,
    uint256 bridgedBalance
  ) external onlyFactory returns (bool) {
    if (
      tokenPayment.tokenType == V1TokenTypes.Native &&
      tokenPayment.tokenIdentifier.toAddress() == address(0)
    ) {
      uint256 availableBalance = address(this).balance - bridgedBalance;
      for (uint i = 0; i < tokenPayment.payments.length; i++) {
        V1Payment calldata payment = tokenPayment.payments[i];

        if (availableBalance < payment.amount) {
          return false;
        }

        availableBalance -= payment.amount;
        address payable target = payable(payment.target.toAddress());
        target.transfer(payment.amount);
      }
    } else if (tokenPayment.tokenType == V1TokenTypes.ERC20) {
      address tokenAddress = tokenPayment.tokenIdentifier.toAddress();
      IERC20 token = IERC20(tokenAddress);
      uint256 availableBalance = token.balanceOf(address(this)) -
        bridgedBalance;

      for (uint i = 0; i < tokenPayment.payments.length; i++) {
        V1Payment calldata payment = tokenPayment.payments[i];

        if (availableBalance < payment.amount) {
          return false;
        }
        availableBalance -= payment.amount;
        token.transfer(payment.target.toAddress(), payment.amount);
      }
    } else {
      revert UnsupportedTokenType(tokenPayment.tokenType);
    }

    return true;
  }

  function sendTokens(
    V1TokenTypes tokenType,
    string calldata tokenIdentifier,
    address payable target,
    uint256 amount
  ) external onlyFactory {
    if (
      tokenType == V1TokenTypes.Native &&
      tokenIdentifier.toAddress() == address(0)
    ) {
      target.transfer(amount);
    } else if (tokenType == V1TokenTypes.ERC20) {
      address tokenAddress = tokenIdentifier.toAddress();
      IERC20 token = IERC20(tokenAddress);

      token.transfer(target, amount);
    } else {
      revert UnsupportedTokenType(tokenType);
    }
  }

  function getBalance(
    V1TokenTypes tokenType,
    string calldata tokenIdentifier
  ) public view returns (uint256) {
    if (tokenType == V1TokenTypes.Native) {
      return address(this).balance;
    } else if (tokenType == V1TokenTypes.ERC20) {
      address tokenAddress = tokenIdentifier.toAddress();
      IERC20 token = IERC20(tokenAddress);

      return token.balanceOf(address(this));
    } else {
      revert UnsupportedTokenType(tokenType);
    }
  }

  function getBalances(
    V1TokenInfo[] calldata tokens
  ) external view returns (uint256[] memory) {
    uint256[] memory balances = new uint256[](tokens.length);

    for (uint i = 0; i < tokens.length; i++) {
      balances[i] = getBalance(
        tokens[i].tokenType,
        tokens[i].tokenIdentifier
      );
    }

    return balances;
  }

  receive() external payable {}
}
