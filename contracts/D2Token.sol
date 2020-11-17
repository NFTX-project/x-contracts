// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "./Ownable.sol";
import "./Context.sol";
import "./ERC20.sol";
import "./ERC20Burnable.sol";

contract D2Token is Context, Ownable, ERC20Burnable {
    address private vaultAddress;

    constructor(string memory name, string memory symbol)
        public
        ERC20(name, symbol)
    {
        initOwnable();
        _mint(msg.sender, 0);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
