//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IVaultController} from '../../IVaultController.sol';
import {V1TokenTypes} from '../V1TokenTypes.sol';

interface IVaultV1Controller is IVaultController {
  function deployVault(
    uint16 chainId,
    uint32 vaultId,
    address transmitUsing
  ) external;

  function addAcceptedGateway(
    uint16 chainId,
    address gatewayToAdd,
    address transmitUsing
  ) external;

  function sendPayment(
    uint16 destinationChainId,
    uint32 vaultId,
    address transmitUsing,
    V1TokenTypes tokenType,
    string calldata tokenIdentifier,
    string calldata target,
    uint256 amount
  ) external;
}
