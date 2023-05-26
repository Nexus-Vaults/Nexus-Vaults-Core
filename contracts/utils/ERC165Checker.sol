//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {IERC165} from '@openzeppelin/contracts/utils/introspection/IERC165.sol';

abstract contract ERC165Checker {
  function _supportsERC165Interface(
    address account,
    bytes4 interfaceId
  ) internal view returns (bool) {
    bytes memory encodedParams = abi.encodeWithSelector(
      IERC165.supportsInterface.selector,
      interfaceId
    );
    (bool success, bytes memory result) = account.staticcall{gas: 30000}(
      encodedParams
    );
    if (result.length < 32) return false;
    return success && abi.decode(result, (bool));
  }
}
