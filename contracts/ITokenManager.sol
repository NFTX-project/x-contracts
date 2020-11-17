// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

interface ITokenManager {
    function mint(address _receiver, uint256 _amount) external;
    function issue(uint256 _amount) external;
    function assign(address _receiver, uint256 _amount) external;
    function burn(address _holder, uint256 _amount) external;
    function assignVested(
        address _receiver,
        uint256 _amount,
        uint64 _start,
        uint64 _cliff,
        uint64 _vested,
        bool _revokable
    ) external returns (uint256);
    function revokeVesting(address _holder, uint256 _vestingId) external;
}
