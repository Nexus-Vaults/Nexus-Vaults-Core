//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

enum V1PacketTypes {
  Never,
  CreateVault,
  AddAcceptedGateway,
  SendPayment,
  BatchSendPayment,
  RedeemPayment,
  BridgeOut,
  MintIOUTokens
}
