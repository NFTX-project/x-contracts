// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "./EnumerableSet.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IXToken.sol";
import "./IERC721.sol";

contract XStore is Ownable {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.UintSet;

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
        address nftAddress;
        address manager;
        IXToken xToken;
        IERC721 nft;
        EnumerableSet.UintSet holdings;
        EnumerableSet.UintSet reserves;
        mapping(uint256 => bool) isEligible;
        mapping(uint256 => bool) shouldReserve;
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

    Vault[] internal vaults;

    mapping(address => bool) public isExtension;
    uint256 public randNonce;

    constructor() public {
        initOwnable();
    }

    function _getVault(uint256 vaultId) internal view returns (Vault storage) {
        require(vaultId < vaults.length, "Invalid vaultId");
        return vaults[vaultId];
    }

    function vaultsLength() public view returns (uint256) {
        return vaults.length;
    }

    function xTokenAddress(uint256 vaultId) public view returns (address) {
        Vault storage vault = _getVault(vaultId);
        return vault.xTokenAddress;
    }

    function nftAddress(uint256 vaultId) public view returns (address) {
        Vault storage vault = _getVault(vaultId);
        return vault.nftAddress;
    }

    function manager(uint256 vaultId) public view returns (address) {
        Vault storage vault = _getVault(vaultId);
        return vault.manager;
    }

    function xToken(uint256 vaultId) public view returns (IXToken) {
        Vault storage vault = _getVault(vaultId);
        return vault.xToken;
    }

    function nft(uint256 vaultId) public view returns (IERC721) {
        Vault storage vault = _getVault(vaultId);
        return vault.nft;
    }

    function holdingsLength(uint256 vaultId) public view returns (uint256) {
        Vault storage vault = _getVault(vaultId);
        return vault.holdings.length();
    }

    function holdingsContains(uint256 vaultId, uint256 elem)
        public
        view
        returns (bool)
    {
        Vault storage vault = _getVault(vaultId);
        return vault.holdings.contains(elem);
    }

    function holdingsAt(uint256 vaultId, uint256 index)
        public
        view
        returns (uint256)
    {
        Vault storage vault = _getVault(vaultId);
        return vault.holdings.at(index);
    }

    function reservesLength(uint256 vaultId) public view returns (uint256) {
        Vault storage vault = _getVault(vaultId);
        return vault.holdings.length();
    }

    function reservesContains(uint256 vaultId, uint256 elem)
        public
        view
        returns (bool)
    {
        Vault storage vault = _getVault(vaultId);
        return vault.holdings.contains(elem);
    }

    function reservesAt(uint256 vaultId, uint256 index)
        public
        view
        returns (uint256)
    {
        Vault storage vault = _getVault(vaultId);
        return vault.holdings.at(index);
    }

    function isEligible(uint256 vaultId, uint256 id)
        public
        view
        returns (bool)
    {
        Vault storage vault = _getVault(vaultId);
        return vault.isEligible[id];
    }

    function shouldReserve(uint256 vaultId, uint256 id)
        public
        view
        returns (bool)
    {
        Vault storage vault = _getVault(vaultId);
        return vault.shouldReserve[id];
    }

    function negateEligibility(uint256 vaultId) public view returns (bool) {
        Vault storage vault = _getVault(vaultId);
        return vault.negateEligibility;
    }

    function isFinalized(uint256 vaultId) public view returns (bool) {
        Vault storage vault = _getVault(vaultId);
        return vault.isFinalized;
    }

    function isClosed(uint256 vaultId) public view returns (bool) {
        Vault storage vault = _getVault(vaultId);
        return vault.isClosed;
    }

    function mintFees(uint256 vaultId) public view returns (uint256, uint256) {
        Vault storage vault = _getVault(vaultId);
        return (vault.mintFees.ethBase, vault.mintFees.ethStep);
    }

    function burnFees(uint256 vaultId) public view returns (uint256, uint256) {
        Vault storage vault = _getVault(vaultId);
        return (vault.burnFees.ethBase, vault.burnFees.ethStep);
    }

    function dualFees(uint256 vaultId) public view returns (uint256, uint256) {
        Vault storage vault = _getVault(vaultId);
        return (vault.dualFees.ethBase, vault.dualFees.ethStep);
    }

    function supplierBounty(uint256 vaultId)
        public
        view
        returns (uint256, uint256)
    {
        Vault storage vault = _getVault(vaultId);
        return (vault.supplierBounty.ethMax, vault.supplierBounty.length);
    }

    function ethBalance(uint256 vaultId) public view returns (uint256) {
        Vault storage vault = _getVault(vaultId);
        return vault.ethBalance;
    }

    function tokenBalance(uint256 vaultId) public view returns (uint256) {
        Vault storage vault = _getVault(vaultId);
        return vault.tokenBalance;
    }

    function isD2Vault(uint256 vaultId) public view returns (bool) {
        Vault storage vault = _getVault(vaultId);
        return vault.isD2Vault;
    }

    function d2AssetAddress(uint256 vaultId) public view returns (address) {
        Vault storage vault = _getVault(vaultId);
        return vault.d2AssetAddress;
    }

    function d2Asset(uint256 vaultId) public view returns (IERC20) {
        Vault storage vault = _getVault(vaultId);
        return vault.d2Asset;
    }

    function d2Holdings(uint256 vaultId) public view returns (uint256) {
        Vault storage vault = _getVault(vaultId);
        return vault.d2Holdings;
    }

    function setXTokenAddress(uint256 vaultId, address _xTokenAddress)
        public
        onlyOwner
    {
        Vault storage vault = _getVault(vaultId);
        vault.xTokenAddress = _xTokenAddress;
    }

    function setAssetAddress(uint256 vaultId, address _nftAddress)
        public
        onlyOwner
    {
        Vault storage vault = _getVault(vaultId);
        vault.nftAddress = _nftAddress;
    }

    function setManager(uint256 vaultId, address _manager) public onlyOwner {
        Vault storage vault = _getVault(vaultId);
        vault.manager = _manager;
    }

    function setXToken(uint256 vaultId) public onlyOwner {
        Vault storage vault = _getVault(vaultId);
        vault.xToken = IXToken(vault.xTokenAddress);
    }

    function setNft(uint256 vaultId) public onlyOwner {
        Vault storage vault = _getVault(vaultId);
        vault.nft = IERC721(vault.nftAddress);
    }

    function holdingsAdd(uint256 vaultId, uint256 elem) public onlyOwner {
        Vault storage vault = _getVault(vaultId);
        vault.holdings.add(elem);
    }

    function holdingsRemove(uint256 vaultId, uint256 elem) public onlyOwner {
        Vault storage vault = _getVault(vaultId);
        vault.holdings.remove(elem);
    }

    function reservesAdd(uint256 vaultId, uint256 elem) public onlyOwner {
        Vault storage vault = _getVault(vaultId);
        vault.reserves.add(elem);
    }

    function reservesRemove(uint256 vaultId, uint256 elem) public onlyOwner {
        Vault storage vault = _getVault(vaultId);
        vault.reserves.remove(elem);
    }

    function setIsEligible(uint256 vaultId, uint256 id, bool _bool)
        public
        onlyOwner
    {
        Vault storage vault = _getVault(vaultId);
        vault.isEligible[id] = _bool;
    }

    function setShouldReserve(uint256 vaultId, uint256 id, bool _shouldReserve)
        public
        onlyOwner
    {
        Vault storage vault = _getVault(vaultId);
        vault.shouldReserve[id] = _shouldReserve;
    }

    function setNegateEligibility(uint256 vaultId, bool negateElig)
        public
        onlyOwner
    {
        Vault storage vault = _getVault(vaultId);
        vault.negateEligibility = negateElig;
    }

    function setIsFinalized(uint256 vaultId, bool _isFinalized)
        public
        onlyOwner
    {
        Vault storage vault = _getVault(vaultId);
        vault.isFinalized = _isFinalized;
    }

    function setIsClosed(uint256 vaultId, bool _isClosed) public onlyOwner {
        Vault storage vault = _getVault(vaultId);
        vault.isClosed = _isClosed;
    }

    function setMintFees(uint256 vaultId, uint256 ethBase, uint256 ethStep)
        public
        onlyOwner
    {
        Vault storage vault = _getVault(vaultId);
        vault.mintFees = FeeParams(ethBase, ethStep);
    }

    function setBurnFees(uint256 vaultId, uint256 ethBase, uint256 ethStep)
        public
        onlyOwner
    {
        Vault storage vault = _getVault(vaultId);
        vault.burnFees = FeeParams(ethBase, ethStep);
    }

    function setDualFees(uint256 vaultId, uint256 ethBase, uint256 ethStep)
        public
        onlyOwner
    {
        Vault storage vault = _getVault(vaultId);
        vault.dualFees = FeeParams(ethBase, ethStep);
    }

    function setSupplierBounty(uint256 vaultId, uint256 ethMax, uint256 length)
        public
        onlyOwner
    {
        Vault storage vault = _getVault(vaultId);
        vault.supplierBounty = BountyParams(ethMax, length);
    }

    function setEthBalance(uint256 vaultId, uint256 _ethBalance)
        public
        onlyOwner
    {
        Vault storage vault = _getVault(vaultId);
        vault.ethBalance = _ethBalance;
    }

    function setTokenBalance(uint256 vaultId, uint256 _tokenBalance)
        public
        onlyOwner
    {
        Vault storage vault = _getVault(vaultId);
        vault.tokenBalance = _tokenBalance;
    }

    function setIsD2Vault(uint256 vaultId, bool _isD2Vault) public onlyOwner {
        Vault storage vault = _getVault(vaultId);
        vault.isD2Vault = _isD2Vault;
    }

    function setD2Asset(uint256 vaultId) public onlyOwner {
        Vault storage vault = _getVault(vaultId);
        vault.d2Asset = IERC20(vault.nftAddress);
    }

    function setD2Holdings(uint256 vaultId, uint256 _d2Holdings)
        public
        onlyOwner
    {
        Vault storage vault = _getVault(vaultId);
        vault.d2Holdings = _d2Holdings;
    }

    ////////////////////////////////////////////////////////////

    function setIsExtension(address addr, bool _isExtension) public onlyOwner {
        isExtension[addr] = _isExtension;
    }

    function setRandNonce(uint256 _randNonce) public onlyOwner {
        randNonce = _randNonce;
    }

    function addNewVault() public onlyOwner returns (uint256) {
        Vault memory newVault;
        vaults.push(newVault);
        return vaults.length.sub(1);
    }

}
