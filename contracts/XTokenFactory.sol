// SPDX-License-Identifier: MIT
pragma solidity 0.6.8;

import "./ModifiedOwnable.sol";
import "./XTokenClonable.sol";

contract CloneFactory {

  function createClone(address target) internal returns (address result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(clone, 0x14), targetBytes)
      mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      result := create(0, clone, 0x37)
    }
  }
}

contract XTokenFactory is CloneFactory, MOwnable {

  address public template;

  event NewXToken(address _xTokenAddress);

  constructor(address _template) public {
    template = _template;
  }

  function createXToken(
    string calldata name,
    string calldata symbol
  ) external returns (XTokenClonable) {
    XTokenClonable x = XTokenClonable(createClone(template));
    x.init(name, symbol, owner());
    emit NewXToken(address(x));
    return x;
  }
}