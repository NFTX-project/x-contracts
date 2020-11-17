// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "./SafeMath.sol";
import "./Pausable.sol";
import "./INFTX.sol";
import "./IXStore.sol";
import "./IERC721.sol";
import "./ITokenManager.sol";
import "./Context.sol";
import "./ReentrancyGuard.sol";

contract XSale is Pausable, ReentrancyGuard {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

    INFTX public nftx;
    IXStore public xStore;
    IERC20 public nftxToken;
    ITokenManager public tokenManager;

    uint64 public constant vestedUntil = 1610697600000; // Fri Jan 15 2021 00:00:00 GMT-0800

    // Bounty[] public ethBounties;
    mapping(uint256 => Bounty[]) public xBounties;

    struct Bounty {
        uint256 reward;
        uint256 request;
    }

    constructor(address _nftx, address _nftxToken, address _tokenManager)
        public
    {
        initOwnable();
        nftx = INFTX(_nftx);
        xStore = IXStore(nftx.store());
        nftxToken = IERC20(_nftxToken);
        tokenManager = ITokenManager(_tokenManager);
    }

    function addXBounty(uint256 vaultId, uint256 reward, uint256 request)
        public
        onlyOwner
    {
        Bounty memory newXBounty;
        newXBounty.reward = reward;
        newXBounty.request = request;
        xBounties[vaultId].push(newXBounty);
    }

    function setXBounty(
        uint256 vaultId,
        uint256 xBountyIndex,
        uint256 newReward,
        uint256 newRequest
    ) public onlyOwner {
        Bounty storage xBounty = xBounties[vaultId][xBountyIndex];
        xBounty.reward = newReward;
        xBounty.request = newRequest;
    }

    function withdrawNFTX(address to, uint256 amount) public onlyOwner {
        nftxToken.transfer(to, amount);
    }

    function withdrawXToken(uint256 vaultId, address to, uint256 amount)
        public
        onlyOwner
    {
        xStore.xToken(vaultId).transfer(to, amount);
    }

    function withdrawETH(address payable to, uint256 amount) public onlyOwner {
        to.transfer(amount);
    }

    function fillXBounty(uint256 vaultId, uint256 xBountyIndex, uint256 amount)
        public
        nonReentrant
    {
        Bounty storage xBounty = xBounties[vaultId][xBountyIndex];
        require(amount <= xBounty.request, "Amount > bounty");
        require(
            amount <= nftxToken.balanceOf(address(nftx)),
            "Amount > balance"
        );
        xStore.xToken(vaultId).transferFrom(
            _msgSender(),
            address(nftx),
            amount
        );
        uint256 reward = xBounty.reward.mul(amount).div(xBounty.request);
        xBounty.request = xBounty.request.sub(amount);
        xBounty.reward = xBounty.reward.sub(reward);
        nftxToken.transfer(address(tokenManager), reward);
        tokenManager.assignVested(
            _msgSender(),
            reward,
            vestedUntil,
            vestedUntil,
            vestedUntil,
            false
        );
    }
}
