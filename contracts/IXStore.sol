// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "./EnumerableSet.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IXToken.sol";
import "./IERC721.sol";
import "./EnumerableSet.sol";

interface IXStore {
    struct FeeParams {
        uint256 ethBase;
        uint256 ethStep;
    }

    struct BountyParams {
        uint256 ethMax;
        uint256 length;
    }

    struct Vault {
        address xTokenAddress;
        address assetAddress;
        address manager;
        IXToken xToken;
        IERC721 nft;
        EnumerableSet.UintSet holdings;
        EnumerableSet.UintSet reserves;
        mapping(uint256 => address) requester;
        mapping(uint256 => bool) isEligible;
        mapping(uint256 => bool) shouldReserve;
        bool flipEligOnRedeem;
        bool negateEligibility;
        bool isFinalized;
        bool isClosed;
        FeeParams mintFees;
        FeeParams burnFees;
        FeeParams dualFees;
        BountyParams supplierBounty;
        uint256 ethBalance;
        uint256 tokenBalance;
        bool isD2Vault;
        address d2AssetAddress;
        IERC20 d2Asset;
        uint256 d2Holdings;
    }

    function isExtension(address addr) external view returns (bool);

    function randNonce() external view returns (uint256);

    function vaultsLength() external view returns (uint256);

    function xTokenAddress(uint256 vaultId) external view returns (address);

    function assetAddress(uint256 vaultId) external view returns (address);

    function manager(uint256 vaultId) external view returns (address);

    function xToken(uint256 vaultId) external view returns (IXToken);

    function nft(uint256 vaultId) external view returns (IERC721);

    function holdingsLength(uint256 vaultId) external view returns (uint256);

    function holdingsContains(uint256 vaultId, uint256 elem)
        external
        view
        returns (bool);

    function holdingsAt(uint256 vaultId, uint256 index)
        external
        view
        returns (uint256);

    function reservesLength(uint256 vaultId) external view returns (uint256);

    function reservesContains(uint256 vaultId, uint256 elem)
        external
        view
        returns (bool);

    function reservesAt(uint256 vaultId, uint256 index)
        external
        view
        returns (uint256);

    function requester(uint256 vaultId, uint256 id)
        external
        view
        returns (address);

    function isEligible(uint256 vaultId, uint256 id)
        external
        view
        returns (bool);

    function shouldReserve(uint256 vaultId, uint256 id)
        external
        view
        returns (bool);

    function flipEligOnRedeem(uint256 vaultId) external view returns (bool);

    function negateEligibility(uint256 vaultId) external view returns (bool);

    function isFinalized(uint256 vaultId) external view returns (bool);

    function isClosed(uint256 vaultId) external view returns (bool);

    function mintFees(uint256 vaultId) external view returns (uint256, uint256);

    function burnFees(uint256 vaultId) external view returns (uint256, uint256);

    function dualFees(uint256 vaultId) external view returns (uint256, uint256);

    function supplierBounty(uint256 vaultId)
        external
        view
        returns (uint256, uint256);

    function ethBalance(uint256 vaultId) external view returns (uint256);

    function tokenBalance(uint256 vaultId) external view returns (uint256);

    function isD2Vault(uint256 vaultId) external view returns (bool);

    function d2AssetAddress(uint256 vaultId) external view returns (address);

    function d2Asset(uint256 vaultId) external view returns (IERC20);

    function d2Holdings(uint256 vaultId) external view returns (uint256);

    function setXTokenAddress(uint256 vaultId, address _xTokenAddress) external;

    function setNftAddress(uint256 vaultId, address _assetAddress) external;

    function setManager(uint256 vaultId, address _manager) external;

    function setXToken(uint256 vaultId) external;

    function setNft(uint256 vaultId) external;

    function holdingsAdd(uint256 vaultId, uint256 elem) external;

    function holdingsRemove(uint256 vaultId, uint256 elem) external;

    function reservesAdd(uint256 vaultId, uint256 elem) external;

    function reservesRemove(uint256 vaultId, uint256 elem) external;

    function setRequester(uint256 vaultId, uint256 id, address _requester)
        external;

    function setIsEligible(uint256 vaultId, uint256 id, bool _bool) external;

    function setShouldReserve(uint256 vaultId, uint256 id, bool _shouldReserve)
        external;

    function setFlipEligOnRedeem(uint256 vaultId, bool flipElig) external;

    function setNegateEligibility(uint256 vaultId, bool negateElig) external;

    function setIsFinalized(uint256 vaultId, bool _isFinalized) external;

    function setIsClosed(uint256 vaultId, bool _isClosed) external;

    function setMintFees(uint256 vaultId, uint256 ethBase, uint256 ethStep)
        external;

    function setBurnFees(uint256 vaultId, uint256 ethBase, uint256 ethStep)
        external;

    function setDualFees(uint256 vaultId, uint256 ethBase, uint256 ethStep)
        external;

    function setSupplierBounty(uint256 vaultId, uint256 ethMax, uint256 length)
        external;

    function setEthBalance(uint256 vaultId, uint256 _ethBalance) external;

    function setTokenBalance(uint256 vaultId, uint256 _tokenBalance) external;

    function setIsD2Vault(uint256 vaultId, bool _isD2Vault) external;

    function setD2AssetAddress(uint256 vaultId, address _assetAddress) external;

    function setD2Asset(uint256 vaultId) external;

    function setD2Holdings(uint256 vaultId, uint256 _d2Holdings) external;

    ////////////////////////////////////////////////////////////

    function setIsExtension(address addr, bool _isExtension) external;

    function setRandNonce(uint256 _randNonce) external;

    function addNewVault() external returns (uint256);
}
