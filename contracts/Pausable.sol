// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "./Ownable.sol";
import "./SafeMath.sol";

contract Pausable is Ownable {
    mapping(uint256 => bool) isPaused;
    // 0 : createVault
    // 1 : mint
    // 2 : redeem
    // 3 : mintAndRedeem

    function onlyOwnerIfPaused(uint256 pauserId) public view virtual {
        require(!isPaused[pauserId] || msg.sender == owner(), "Paused");
    }

    function setPaused(uint256 pauserId, bool _isPaused)
        public
        virtual
        onlyOwner
    {
        isPaused[pauserId] = _isPaused;
    }
}
