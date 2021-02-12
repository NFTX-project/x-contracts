// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "./IERC20.sol";

interface IXTokenClonable is IERC20 {

    function initialize(string calldata name, string calldata symbol, address _owner) external;

    function owner() external returns (address);

    function burn(uint256 amount) external;

    function burnFrom(address account, uint256 amount) external;

    function mint(address to, uint256 amount) external;

    function changeName(string calldata name) external;

    function changeSymbol(string calldata symbol) external;

    function transferOwnership(address newOwner) external;
}