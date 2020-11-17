// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "./Pausable.sol";
import "./IXToken.sol";
import "./IERC721.sol";
import "./EnumerableSet.sol";
import "./ReentrancyGuard.sol";
import "./SafeMath.sol";

interface INFTX {
    event NFTsDeposited(uint256 vaultId, uint256[] nftIds, address from);
    event NFTsRedeemed(uint256 vaultId, uint256[] nftIds, address to);
    event TokensMinted(uint256 vaultId, uint256 amount, address to);
    event TokensBurned(uint256 vaultId, uint256 amount, address from);

    event EligibilitySet(uint256 vaultId, uint256[] nftIds, bool _boolean);
    event ReservesIncreased(uint256 vaultId, uint256 nftId);
    event ReservesDecreased(uint256 vaultId, uint256 nftId);

    function store() external returns (address);

    function transferOwnership(address newOwner) external;

    function vaultSize(uint256 vaultId) external view returns (uint256);

    function isEligible(uint256 vaultId, uint256 nftId)
        external
        view
        returns (bool);

    function createVault(address _erc20Address, address _nftAddress)
        external
        returns (uint256);

    function depositETH(uint256 vaultId) external payable;

    function setIsEligible(
        uint256 vaultId,
        uint256[] calldata nftIds,
        bool _boolean
    ) external;

    function setNegateEligibility(uint256 vaultId, bool shouldNegate) external;

    function setShouldReserve(
        uint256 vaultId,
        uint256[] calldata nftIds,
        bool _boolean
    ) external;

    function setIsReserved(
        uint256 vaultId,
        uint256[] calldata nftIds,
        bool _boolean
    ) external;

    function setExtension(address contractAddress, bool _boolean) external;

    function directRedeem(uint256 vaultId, uint256[] calldata nftIds)
        external
        payable;

    function mint(uint256 vaultId, uint256[] calldata nftIds, uint256 d2Amount)
        external
        payable;

    function redeem(uint256 vaultId, uint256 numNFTs) external payable;

    function mintAndRedeem(uint256 vaultId, uint256[] calldata nftIds)
        external
        payable;

    function changeTokenName(uint256 vaultId, string calldata newName) external;

    function changeTokenSymbol(uint256 vaultId, string calldata newSymbol)
        external;

    function setManager(uint256 vaultId, address newManager) external;

    function finalizeVault(uint256 vaultId) external;

    function closeVault(uint256 vaultId) external;

    function setMintFees(uint256 vaultId, uint256 _ethBase, uint256 _ethStep)
        external;

    function setBurnFees(uint256 vaultId, uint256 _ethBase, uint256 _ethStep)
        external;

    function setDualFees(uint256 vaultId, uint256 _ethBase, uint256 _ethStep)
        external;

    function setSupplierBounty(uint256 vaultId, uint256 ethMax, uint256 length)
        external;
}
