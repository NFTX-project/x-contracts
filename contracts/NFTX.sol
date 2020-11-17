// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "./Pausable.sol";
import "./IXToken.sol";
import "./IERC721.sol";
import "./ReentrancyGuard.sol";
import "./ERC721Holder.sol";
import "./IXStore.sol";
import "./Initializable.sol";

contract NFTX is Pausable, ReentrancyGuard, ERC721Holder {
    using SafeMath for uint256;

    event NewVault(uint256 vaultId);

    IXStore public store;

    function initialize(address storeAddress) public initializer {
        initOwnable();
        initReentrancyGuard();
        store = IXStore(storeAddress);
    }

    function onlyExtension() public view virtual {
        require(store.isExtension(_msgSender()), "Not extension");
    }

    function onlyManager(uint256 vaultId) internal view {
        require(_msgSender() == store.manager(vaultId), "Not manager");
    }

    function onlyPrivileged(uint256 vaultId) internal view {
        if (store.isFinalized(vaultId)) {
            require(_msgSender() == owner(), "Not owner");
        } else {
            onlyManager(vaultId);
        }
    }

    function isEligible(uint256 vaultId, uint256 nftId)
        public
        view
        virtual
        returns (bool)
    {
        return
            store.negateEligibility(vaultId)
                ? !store.isEligible(vaultId, nftId)
                : store.isEligible(vaultId, nftId);
    }

    function vaultSize(uint256 vaultId) public view virtual returns (uint256) {
        return
            store.isD2Vault(vaultId)
                ? store.d2Holdings(vaultId)
                : store.holdingsLength(vaultId).add(
                    store.reservesLength(vaultId)
                );
    }

    function _getPseudoRand(uint256 modulus)
        internal
        virtual
        returns (uint256)
    {
        store.setRandNonce(store.randNonce().add(1));
        return
            uint256(
                keccak256(abi.encodePacked(now, msg.sender, store.randNonce()))
            ) %
            modulus;
    }

    function _calcFee(
        uint256 amount,
        uint256 ethBase,
        uint256 ethStep,
        bool isD2
    ) internal pure virtual returns (uint256) {
        if (amount == 0) {
            return 0;
        } else if (isD2) {
            return ethBase.add(ethStep.mul(amount.sub(10**18)).div(10**18));
        } else {
            uint256 n = amount;
            uint256 nSub1 = amount >= 1 ? n.sub(1) : 0;
            return ethBase.add(ethStep.mul(nSub1));
        }
    }

    function _calcBounty(uint256 vaultId, uint256 numTokens, bool isBurn)
        public
        view
        virtual
        returns (uint256)
    {
        (, uint256 length) = store.supplierBounty(vaultId);
        if (length == 0) return 0;
        uint256 ethBounty = 0;
        for (uint256 i = 0; i < numTokens; i = i.add(1)) {
            uint256 _vaultSize = isBurn
                ? vaultSize(vaultId).sub(i.add(1))
                : vaultSize(vaultId).add(i);
            uint256 _ethBounty = _calcBountyHelper(vaultId, _vaultSize);
            ethBounty = ethBounty.add(_ethBounty);
        }
        return ethBounty;
    }

    function _calcBountyD2(uint256 vaultId, uint256 amount, bool isBurn)
        public
        view
        virtual
        returns (uint256)
    {
        (uint256 ethMax, uint256 length) = store.supplierBounty(vaultId);
        if (length == 0) return 0;
        uint256 prevSize = vaultSize(vaultId);
        uint256 prevDepth = prevSize > length ? 0 : length.sub(prevSize);
        uint256 prevReward = _calcBountyD2Helper(ethMax, length, prevSize);
        uint256 newSize = isBurn
            ? vaultSize(vaultId).sub(amount)
            : vaultSize(vaultId).add(amount);
        uint256 newDepth = newSize > length ? 0 : length.sub(newSize);
        uint256 newReward = _calcBountyD2Helper(ethMax, length, newSize);
        uint256 prevTriangle = prevDepth.mul(prevReward).div(2).div(10**18);
        uint256 newTriangle = newDepth.mul(newReward).div(2).div(10**18);

        return
            isBurn
                ? newTriangle.sub(prevTriangle)
                : prevTriangle.sub(newTriangle);
    }

    function _calcBountyD2Helper(uint256 ethMax, uint256 length, uint256 size)
        internal
        pure
        returns (uint256)
    {
        if (size >= length) return 0;
        return ethMax.sub(ethMax.mul(size).div(length));
    }

    function _calcBountyHelper(uint256 vaultId, uint256 _vaultSize)
        internal
        view
        virtual
        returns (uint256)
    {
        (uint256 ethMax, uint256 length) = store.supplierBounty(vaultId);
        if (_vaultSize >= length) return 0;
        uint256 depth = length.sub(_vaultSize);
        return ethMax.div(length).mul(depth);
    }

    function createVault(
        address _xTokenAddress,
        address _assetAddress,
        bool _isD2Vault
    ) public virtual nonReentrant returns (uint256) {
        onlyOwnerIfPaused(0);
        IXToken xToken = IXToken(_xTokenAddress);
        require(xToken.owner() == address(this), "Wrong owner");
        uint256 vaultId = store.addNewVault();
        store.setXTokenAddress(vaultId, _xTokenAddress);
        store.setAssetAddress(vaultId, _assetAddress);
        store.setXToken(vaultId);
        if (!_isD2Vault) {
            store.setNft(vaultId);
            store.setNegateEligibility(vaultId, true);
        } else {
            store.setD2Asset(vaultId);
            store.setIsD2Vault(vaultId, true);
        }
        store.setManager(vaultId, _msgSender());
        emit NewVault(vaultId);
        return vaultId;
    }

    function depositETH(uint256 vaultId) public payable virtual {
        store.setEthBalance(vaultId, store.ethBalance(vaultId).add(msg.value));
    }

    function setExtension(address contractAddress, bool _boolean)
        public
        virtual
        onlyOwner
    {
        require(_boolean != store.isExtension(contractAddress), "Already set");
        store.setIsExtension(contractAddress, _boolean);
    }

    function _payEthFromVault(
        uint256 vaultId,
        uint256 amount,
        address payable to
    ) internal virtual {
        uint256 ethBalance = store.ethBalance(vaultId);
        uint256 amountToSend = ethBalance < amount ? ethBalance : amount;
        if (amountToSend > 0) {
            store.setEthBalance(vaultId, ethBalance.sub(amountToSend));
            to.transfer(amountToSend);
        }
    }

    function _receiveEthToVault(
        uint256 vaultId,
        uint256 amountRequested,
        uint256 amountSent
    ) internal virtual {
        require(amountSent >= amountRequested, "Value too low");
        store.setEthBalance(
            vaultId,
            store.ethBalance(vaultId).add(amountRequested)
        );
    }

    function _mint(uint256 vaultId, uint256[] memory nftIds, bool isDualOp)
        internal
        virtual
    {
        for (uint256 i = 0; i < nftIds.length; i = i.add(1)) {
            uint256 nftId = nftIds[i];
            require(isEligible(vaultId, nftId), "Not eligible");
            require(
                store.nft(vaultId).ownerOf(nftId) != address(this),
                "Already owner"
            );
            store.nft(vaultId).safeTransferFrom(
                _msgSender(),
                address(this),
                nftId
            );
            require(
                store.nft(vaultId).ownerOf(nftId) == address(this),
                "Not received"
            );
            if (store.shouldReserve(vaultId, nftId)) {
                store.reservesAdd(vaultId, nftId);
            } else {
                store.holdingsAdd(vaultId, nftId);
            }
        }
        if (!isDualOp) {
            uint256 amount = nftIds.length.mul(10**18);
            store.xToken(vaultId).mint(_msgSender(), amount);
        }
    }

    function _mintD2(uint256 vaultId, uint256 amount) internal virtual {
        store.d2Asset(vaultId).transferFrom(
            _msgSender(),
            address(this),
            amount
        );
        store.xToken(vaultId).mint(_msgSender(), amount);
        store.setD2Holdings(vaultId, store.d2Holdings(vaultId).add(amount));
    }

    function _redeem(uint256 vaultId, uint256 numNFTs, bool isDualOp)
        internal
        virtual
    {
        for (uint256 i = 0; i < numNFTs; i = i.add(1)) {
            uint256[] memory nftIds = new uint256[](1);
            if (store.holdingsLength(vaultId) > 0) {
                uint256 rand = _getPseudoRand(store.holdingsLength(vaultId));
                nftIds[0] = store.holdingsAt(vaultId, rand);
            } else {
                uint256 rand = _getPseudoRand(store.reservesLength(vaultId));
                nftIds[i] = store.reservesAt(vaultId, rand);
            }
            _redeemHelper(vaultId, nftIds, isDualOp);
        }
    }

    function _redeemD2(uint256 vaultId, uint256 amount) internal virtual {
        store.xToken(vaultId).burnFrom(_msgSender(), amount);
        store.d2Asset(vaultId).transfer(_msgSender(), amount);
        store.setD2Holdings(vaultId, store.d2Holdings(vaultId).sub(amount));
    }

    function _redeemHelper(
        uint256 vaultId,
        uint256[] memory nftIds,
        bool isDualOp
    ) internal virtual {
        if (!isDualOp) {
            store.xToken(vaultId).burnFrom(
                _msgSender(),
                nftIds.length.mul(10**18)
            );
        }
        for (uint256 i = 0; i < nftIds.length; i = i.add(1)) {
            uint256 nftId = nftIds[i];
            require(
                store.holdingsContains(vaultId, nftId) ||
                    store.reservesContains(vaultId, nftId),
                "NFT not in vault"
            );
            if (store.holdingsContains(vaultId, nftId)) {
                store.holdingsRemove(vaultId, nftId);
            } else {
                store.reservesRemove(vaultId, nftId);
            }
            store.nft(vaultId).safeTransferFrom(
                address(this),
                _msgSender(),
                nftId
            );
        }
    }

    function directRedeem(uint256 vaultId, uint256[] memory nftIds)
        public
        payable
        virtual
        nonReentrant
    {
        onlyExtension();
        require(vaultId < store.vaultsLength(), "Invalid vaultId");
        uint256 ethBounty = _calcBounty(vaultId, nftIds.length, true);
        _receiveEthToVault(vaultId, ethBounty, msg.value);
        _redeemHelper(vaultId, nftIds, false);
    }

    function mint(uint256 vaultId, uint256[] memory nftIds, uint256 d2Amount)
        public
        payable
        virtual
        nonReentrant
    {
        onlyOwnerIfPaused(1);
        uint256 amount = store.isD2Vault(vaultId) ? d2Amount : nftIds.length;
        uint256 ethBounty = store.isD2Vault(vaultId)
            ? _calcBountyD2(vaultId, d2Amount, false)
            : _calcBounty(vaultId, amount, false);
        (uint256 ethBase, uint256 ethStep) = store.mintFees(vaultId);
        uint256 ethFee = _calcFee(
            amount,
            ethBase,
            ethStep,
            store.isD2Vault(vaultId)
        );
        if (ethFee > ethBounty) {
            _receiveEthToVault(vaultId, ethFee.sub(ethBounty), msg.value);
        }
        if (store.isD2Vault(vaultId)) {
            _mintD2(vaultId, d2Amount);
        } else {
            _mint(vaultId, nftIds, false);
        }
        if (ethBounty > ethFee) {
            _payEthFromVault(vaultId, ethBounty.sub(ethFee), _msgSender());

        }
    }

    function redeem(uint256 vaultId, uint256 amount)
        public
        payable
        virtual
        nonReentrant
    {
        onlyOwnerIfPaused(2);
        if (!store.isClosed(vaultId)) {
            uint256 ethBounty = store.isD2Vault(vaultId)
                ? _calcBountyD2(vaultId, amount, true)
                : _calcBounty(vaultId, amount, true);
            (uint256 ethBase, uint256 ethStep) = store.burnFees(vaultId);
            uint256 ethFee = _calcFee(
                amount,
                ethBase,
                ethStep,
                store.isD2Vault(vaultId)
            );
            if (ethBounty.add(ethFee) > 0) {
                _receiveEthToVault(vaultId, ethBounty.add(ethFee), msg.value);
            }
        }
        if (!store.isD2Vault(vaultId)) {
            _redeem(vaultId, amount, false);
        } else {
            _redeemD2(vaultId, amount);
        }

    }

    function mintAndRedeem(uint256 vaultId, uint256[] memory nftIds)
        public
        payable
        virtual
        nonReentrant
    {
        onlyOwnerIfPaused(3);
        require(!store.isD2Vault(vaultId), "Is D2 vault");
        require(!store.isClosed(vaultId), "Vault is closed");
        (uint256 ethBase, uint256 ethStep) = store.dualFees(vaultId);
        uint256 ethFee = _calcFee(
            nftIds.length,
            ethBase,
            ethStep,
            store.isD2Vault(vaultId)
        );
        if (ethFee > 0) {
            _receiveEthToVault(vaultId, ethFee, msg.value);
        }
        _mint(vaultId, nftIds, true);
        _redeem(vaultId, nftIds.length, true);
    }

    function setIsEligible(
        uint256 vaultId,
        uint256[] memory nftIds,
        bool _boolean
    ) public virtual {
        onlyPrivileged(vaultId);
        for (uint256 i = 0; i < nftIds.length; i = i.add(1)) {
            store.setIsEligible(vaultId, nftIds[i], _boolean);
        }
    }

    function setNegateEligibility(uint256 vaultId, bool shouldNegate)
        public
        virtual
    {
        onlyPrivileged(vaultId);
        require(
            store
                .holdingsLength(vaultId)
                .add(store.reservesLength(vaultId))
                .add(store.d2Holdings(vaultId)) ==
                0,
            "Vault not empty"
        );
        store.setNegateEligibility(vaultId, shouldNegate);
    }

    function setShouldReserve(
        uint256 vaultId,
        uint256[] memory nftIds,
        bool _boolean
    ) public virtual {
        onlyPrivileged(vaultId);
        for (uint256 i = 0; i < nftIds.length; i.add(1)) {
            store.setShouldReserve(vaultId, nftIds[i], _boolean);
        }
    }

    function setIsReserved(
        uint256 vaultId,
        uint256[] memory nftIds,
        bool _boolean
    ) public virtual {
        onlyPrivileged(vaultId);
        for (uint256 i = 0; i < nftIds.length; i.add(1)) {
            uint256 nftId = nftIds[i];
            if (_boolean) {
                require(
                    store.holdingsContains(vaultId, nftId),
                    "Invalid nftId"
                );
                store.holdingsRemove(vaultId, nftId);
                store.reservesAdd(vaultId, nftId);
            } else {
                require(
                    store.reservesContains(vaultId, nftId),
                    "Invalid nftId"
                );
                store.reservesRemove(vaultId, nftId);
                store.holdingsAdd(vaultId, nftId);
            }
        }
    }

    function changeTokenName(uint256 vaultId, string memory newName)
        public
        virtual
    {
        onlyPrivileged(vaultId);
        store.xToken(vaultId).changeName(newName);
    }

    function changeTokenSymbol(uint256 vaultId, string memory newSymbol)
        public
        virtual
    {
        onlyPrivileged(vaultId);
        store.xToken(vaultId).changeSymbol(newSymbol);
    }

    function setManager(uint256 vaultId, address newManager) public virtual {
        onlyManager(vaultId);
        store.setManager(vaultId, newManager);
    }

    function finalizeVault(uint256 vaultId) public virtual {
        onlyManager(vaultId);
        require(!store.isFinalized(vaultId), "Already finalized");
        store.setIsFinalized(vaultId, true);
    }

    function closeVault(uint256 vaultId) public virtual {
        onlyPrivileged(vaultId);
        store.setIsClosed(vaultId, true);
    }

    function setMintFees(uint256 vaultId, uint256 _ethBase, uint256 _ethStep)
        public
        virtual
    {
        onlyPrivileged(vaultId);
        store.setMintFees(vaultId, _ethBase, _ethStep);
    }

    function setBurnFees(uint256 vaultId, uint256 _ethBase, uint256 _ethStep)
        public
        virtual
    {
        onlyPrivileged(vaultId);
        store.setBurnFees(vaultId, _ethBase, _ethStep);
    }

    function setDualFees(uint256 vaultId, uint256 _ethBase, uint256 _ethStep)
        public
        virtual
    {
        onlyPrivileged(vaultId);
        store.setDualFees(vaultId, _ethBase, _ethStep);
    }

    function setSupplierBounty(uint256 vaultId, uint256 ethMax, uint256 length)
        public
        virtual
    {
        onlyPrivileged(vaultId);
        store.setSupplierBounty(vaultId, ethMax, length);
    }

}
