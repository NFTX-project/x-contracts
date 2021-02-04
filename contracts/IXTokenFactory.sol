// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "./IXTokenClonable.sol";

interface IXTokenFactory {
    function createXToken(string calldata name, string calldata symbol)
        external
        returns (IXTokenClonable);
}
