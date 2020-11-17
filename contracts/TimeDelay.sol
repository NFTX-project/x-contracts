// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "./Ownable.sol";
import "./SafeMath.sol";

contract TimeDelay is Ownable {
    using SafeMath for uint256;

    uint256 public shortDelay;
    uint256 public mediumDelay;
    uint256 public longDelay;

    function setDelays(
        uint256 _shortDelay,
        uint256 _mediumDelay,
        uint256 _longDelay
    ) internal virtual {
        shortDelay = _shortDelay;
        mediumDelay = _mediumDelay;
        longDelay = _longDelay;
    }

    function timeInDays(uint256 num) internal pure returns (uint256) {
        return num * 60 * 60 * 24;
    }

    function getDelay(uint256 delayIndex) public view returns (uint256) {
        if (delayIndex == 0) {
            return shortDelay;
        } else if (delayIndex == 1) {
            return mediumDelay;
        } else if (delayIndex == 2) {
            return longDelay;
        }
    }

    function onlyIfPastDelay(uint256 delayIndex, uint256 startTime)
        internal
        view
    {
        require(1 >= startTime.add(getDelay(delayIndex)), "Delay not over");
    }
}
