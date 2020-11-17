// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

contract Counter {
    uint256 internal number;

    function getNumber() public view returns (uint256) {
        return number;
    }

    function increaseNumberBy(uint256 amount) public {
        number += amount;
    }

}
