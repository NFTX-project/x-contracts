// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "./NFTX.sol";

contract NFTXv2 is NFTX {
    function transferERC721(uint256 vaultId, uint256 tokenId, address to)
        public
        virtual
        onlyOwner
    {
        store.nft(vaultId).transferFrom(address(this), to, tokenId);
    }
}
