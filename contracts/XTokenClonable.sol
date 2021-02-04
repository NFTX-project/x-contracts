// SPDX-License-Identifier: MIT
pragma solidity 0.6.8;

import "./ModifiedOwnable.sol";
import "./ModifiedERC20Burnable.sol";

contract XTokenClonable is MOwnable, MERC20Burnable {
    bool initialized;

    // Note this is never used because we use initializer
    constructor() public MERC20Burnable("", "") {
        initialized = true;
    }

    function init(string calldata name, string calldata symbol, address _owner)
        external
    {
        require(!initialized, "Initialized");
        initialized = true;
        _mint(msg.sender, 0);
        _transferOwnership(_owner);
        _changeName(name);
        _changeSymbol(symbol);
        _setupDecimals(18);
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function changeName(string memory name) public onlyOwner {
        _changeName(name);
    }

    function changeSymbol(string memory symbol) public onlyOwner {
        _changeSymbol(symbol);
    }
}
