// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "./ITransparentUpgradeableProxy.sol";
import "./ControllerBase.sol";

contract UpgradeController is ControllerBase {
    using SafeMath for uint256;

    
    ITransparentUpgradeableProxy private nftxProxy;
    ITransparentUpgradeableProxy private xControllerProxy;

    constructor(address nftx, address xController) public {
        ControllerBase.initialize();
        nftxProxy = ITransparentUpgradeableProxy(nftx);
        xControllerProxy = ITransparentUpgradeableProxy(xController);
    }

    function executeFuncCall(uint256 fcId) public override onlyOwner {
        super.executeFuncCall(fcId);
        if (funcIndex[fcId] == 3) {
            nftxProxy.changeAdmin(addressParam[fcId]);
        } else if (funcIndex[fcId] == 4) {
            nftxProxy.upgradeTo(addressParam[fcId]);
        } else if (funcIndex[fcId] == 5) {
            xControllerProxy.changeAdmin(addressParam[fcId]);
        } else if (funcIndex[fcId] == 6) {
            xControllerProxy.upgradeTo(addressParam[fcId]);
        }
    }

}
