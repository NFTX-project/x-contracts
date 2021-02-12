// SPDX-License-Identifier: MIT
pragma solidity 0.6.8;

interface IXTokenFactory {

  function createXToken(string calldata name, string calldata symbol) external returns (address);

  event NewXToken(address _xTokenAddress);
}
