// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "./ControllerBase.sol";
import "./INFTX.sol";
import "./IXStore.sol";
import "./Initializable.sol";

contract XController is ControllerBase {
    INFTX private nftx;
    IXStore store;

    /* uint256 numFuncCalls;

    mapping(uint256 => uint256) public time;
    mapping(uint256 => uint256) public funcIndex;
    mapping(uint256 => address payable) public addressParam;
    mapping(uint256 => uint256[]) public uintArrayParam; */
    mapping(uint256 => uint256) public uintParam;
    mapping(uint256 => string) public stringParam;
    mapping(uint256 => bool) public boolParam;

    mapping(uint256 => uint256) public pendingEligAdditions;

    function initXController(address nftxAddress) public initializer {
        initOwnable();
        nftx = INFTX(nftxAddress);
    }

    function onlyOwnerOrLeadDev(uint256 funcIndex) public view virtual {
        if (funcIndex > 3) {
            require(
                _msgSender() == leadDev || _msgSender() == owner(),
                "Not owner or leadDev"
            );
        } else {
            require(_msgSender() == owner(), "Not owner");
        }
    }

    function stageFuncCall(
        uint256 _funcIndex,
        address payable _addressParam,
        uint256 _uintParam,
        string memory _stringParam,
        uint256[] memory _uintArrayParam,
        bool _boolParam
    ) public virtual {
        onlyOwnerOrLeadDev(_funcIndex);
        uint256 fcId = numFuncCalls;
        numFuncCalls = numFuncCalls.add(1);
        time[fcId] = 1;
        funcIndex[fcId] = _funcIndex;
        addressParam[fcId] = _addressParam;
        uintParam[fcId] = _uintParam;
        stringParam[fcId] = _stringParam;
        uintArrayParam[fcId] = _uintArrayParam;
        boolParam[fcId] = _boolParam;
        if (
            funcIndex[fcId] == 4 &&
            store.negateEligibility(uintParam[fcId]) != !boolParam[fcId]
        ) {
            pendingEligAdditions[uintParam[fcId]] = pendingEligAdditions[uintParam[fcId]]
                .add(uintArrayParam[fcId].length);
        }
    }

    function cancelFuncCall(uint256 fcId) public override virtual {
        onlyOwnerOrLeadDev(funcIndex[fcId]);
        require(funcIndex[fcId] != 0, "Already cancelled");
        funcIndex[fcId] = 0;
        if (
            funcIndex[fcId] == 3 &&
            store.negateEligibility(uintParam[fcId]) != !boolParam[fcId]
        ) {
            pendingEligAdditions[uintParam[fcId]] = pendingEligAdditions[uintParam[fcId]]
                .sub(uintArrayParam[fcId].length);
        }
    }

    function executeFuncCall(uint256 fcId) public override virtual {
        super.executeFuncCall(fcId);
        if (funcIndex[fcId] == 3) {
            onlyIfPastDelay(2, time[fcId]);
            nftx.transferOwnership(addressParam[fcId]);
        } else if (funcIndex[fcId] == 4) {
            uint256 percentInc = pendingEligAdditions[uintParam[fcId]]
                .mul(100)
                .div(nftx.vaultSize(uintParam[fcId]));
            if (percentInc > 10) {
                onlyIfPastDelay(2, time[fcId]);
            } else if (percentInc > 1) {
                onlyIfPastDelay(1, time[fcId]);
            } else {
                onlyIfPastDelay(0, time[fcId]);
            }
            nftx.setIsEligible(
                uintParam[fcId],
                uintArrayParam[fcId],
                boolParam[fcId]
            );
            pendingEligAdditions[uintParam[fcId]] = pendingEligAdditions[uintParam[fcId]]
                .sub(uintArrayParam[fcId].length);
        } else if (funcIndex[fcId] == 5) {
            onlyIfPastDelay(0, time[fcId]); // vault must be empty
            nftx.setNegateEligibility(funcIndex[fcId], boolParam[fcId]);
        } else if (funcIndex[fcId] == 6) {
            onlyIfPastDelay(0, time[fcId]);
            nftx.setShouldReserve(
                uintParam[fcId],
                uintArrayParam[fcId],
                boolParam[fcId]
            );
        } else if (funcIndex[fcId] == 7) {
            onlyIfPastDelay(0, time[fcId]);
            nftx.setIsReserved(
                uintParam[fcId],
                uintArrayParam[fcId],
                boolParam[fcId]
            );
        } else if (funcIndex[fcId] == 8) {
            onlyIfPastDelay(1, time[fcId]);
            nftx.changeTokenName(uintParam[fcId], stringParam[fcId]);
        } else if (funcIndex[fcId] == 9) {
            onlyIfPastDelay(1, time[fcId]);
            nftx.changeTokenSymbol(uintParam[fcId], stringParam[fcId]);
        } else if (funcIndex[fcId] == 10) {
            onlyIfPastDelay(0, time[fcId]);
            nftx.closeVault(uintParam[fcId]);
        } else if (funcIndex[fcId] == 11) {
            onlyIfPastDelay(0, time[fcId]);
            nftx.setMintFees(
                uintArrayParam[fcId][0],
                uintArrayParam[fcId][1],
                uintArrayParam[fcId][2]
            );
        } else if (funcIndex[fcId] == 12) {
            (uint256 ethBase, uint256 ethStep) = store.burnFees(
                uintArrayParam[fcId][0]
            );
            uint256 ethBasePercentInc = uintArrayParam[fcId][1].mul(100).div(
                ethBase
            );
            uint256 ethStepPercentInc = uintArrayParam[fcId][2].mul(100).div(
                ethStep
            );
            if (ethBasePercentInc.add(ethStepPercentInc) > 15) {
                onlyIfPastDelay(2, time[fcId]);
            } else if (ethBasePercentInc.add(ethStepPercentInc) > 5) {
                onlyIfPastDelay(1, time[fcId]);
            } else {
                onlyIfPastDelay(0, time[fcId]);
            }
            nftx.setBurnFees(
                uintArrayParam[fcId][0],
                uintArrayParam[fcId][1],
                uintArrayParam[fcId][2]
            );
        } else if (funcIndex[fcId] == 13) {
            onlyIfPastDelay(0, time[fcId]);
            nftx.setDualFees(
                uintArrayParam[fcId][0],
                uintArrayParam[fcId][1],
                uintArrayParam[fcId][2]
            );
        } else if (funcIndex[fcId] == 14) {
            (uint256 ethMax, uint256 length) = store.supplierBounty(
                uintArrayParam[fcId][0]
            );
            uint256 ethMaxPercentInc = uintArrayParam[fcId][1].mul(100).div(
                ethMax
            );
            uint256 lengthPercentInc = uintArrayParam[fcId][2].mul(100).div(
                length
            );
            if (ethMaxPercentInc.add(lengthPercentInc) > 20) {
                onlyIfPastDelay(2, time[fcId]);
            } else if (ethMaxPercentInc.add(lengthPercentInc) > 5) {
                onlyIfPastDelay(1, time[fcId]);
            } else {
                onlyIfPastDelay(0, time[fcId]);
            }
            nftx.setSupplierBounty(
                uintArrayParam[fcId][0],
                uintArrayParam[fcId][1],
                uintArrayParam[fcId][2]
            );
        }
    }

}
