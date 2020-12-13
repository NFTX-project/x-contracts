// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

import "./Context.sol";
import "./ERC721.sol";

contract ERC721Public is Context, ERC721 {
    uint256 public minTokenId;
    uint256 public maxTokenId;

    constructor(
        string memory name,
        string memory symbol,
        uint256 _minTokenId,
        uint256 _maxTokenId
    ) public ERC721(name, symbol) {
        minTokenId = _minTokenId;
        maxTokenId = _maxTokenId;
    }

    function mint(uint256 tokenId, address recipient) public {
        require(tokenId >= minTokenId, "tokenId < minTokenId");
        require(tokenId <= maxTokenId, "tokenId > maxTokenId");
        _mint(recipient, tokenId);
    }

}
