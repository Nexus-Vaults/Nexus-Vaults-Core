//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

enum V1PacketTypes {
  Never,
  CreateVault,
  EnableGateway,
  SendPayment,
  RedeemPayment,
  BridgeOut,
  MintIOUTokens
}
