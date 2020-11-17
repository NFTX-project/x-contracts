// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "./Timelocked.sol";
import "./SafeMath.sol";
import "./Initializable.sol";

abstract contract ControllerBase is Timelocked {
    using SafeMath for uint256;

    address public leadDev;

    uint256 numFuncCalls;

    mapping(uint256 => uint256) public time;
    mapping(uint256 => uint256) public funcIndex;
    mapping(uint256 => address payable) public addressParam;
    mapping(uint256 => uint256[]) public uintArrayParam;

    function transferOwnership(address newOwner) public override virtual {
        uint256 fcId = numFuncCalls;
        numFuncCalls = numFuncCalls.add(1);
        time[fcId] = now;
        funcIndex[fcId] = 0;
        addressParam[fcId] = payable(newOwner);
    }

    function initialize() public initializer {
        initOwnable();
    }

    function setLeadDev(address newLeadDev) public virtual onlyOwner {
        leadDev = newLeadDev;
    }

    function stageFuncCall(
        uint256 _funcIndex,
        address payable _addressParam,
        uint256[] memory _uintArrayParam
    ) public virtual onlyOwner {
        uint256 fcId = numFuncCalls;
        numFuncCalls = numFuncCalls.add(1);
        time[fcId] = now;
        funcIndex[fcId] = _funcIndex;
        addressParam[fcId] = _addressParam;
        uintArrayParam[fcId] = _uintArrayParam;
    }

    function cancelFuncCall(uint256 fcId) public virtual onlyOwner {
        funcIndex[fcId] = 0;
    }

    function executeFuncCall(uint256 fcId) public virtual {
        if (funcIndex[fcId] == 0) {
            return;
        } else if (funcIndex[fcId] == 1) {
            require(
                    uintArrayParam[fcId][2] >= uintArrayParam[fcId][1] &&
                        uintArrayParam[fcId][1] >= uintArrayParam[fcId][0],
                    "Invalid delays"
                );
            if (uintArrayParam[fcId][2] != longDelay) {
                onlyIfPastDelay(2, time[fcId]);
            } else if (uintArrayParam[fcId][1] != mediumDelay) {
                onlyIfPastDelay(1, time[fcId]);
            } else {
                onlyIfPastDelay(0, time[fcId]);
            }
            setDelays(
                uintArrayParam[fcId][0],
                uintArrayParam[fcId][1],
                uintArrayParam[fcId][2]
            );
        } else if (funcIndex[fcId] == 2) {
            onlyIfPastDelay(1, time[fcId]);
            Ownable.transferOwnership(addressParam[fcId]);
        }
    }
}
