// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 */
interface ISecurityToken {
    function setupSecurityToken(address manager_) external;
    function grantValidator(address account) external returns (bool);
    function revokeValidator(address account) external returns (bool);
    function enableOwner(address owner) external returns (bool);
    function disableOwner(address owner) external returns (bool);
    function isValidOwner(address owner) external returns (bool);
    function enableSecurity(uint128 securityId) external returns (bool);
    function disableSecurity(uint128 securityId) external returns (bool);
    function enableHolding(uint128 holdingId) external returns (bool);
    function disableHolding(uint128 holdingId) external returns (bool);
    function processHoldingEvent(HoldingEvent calldata h) external returns (bool);
    function listSecurities() public view returns (Security[] memory);
    function listOwners() public view returns (SecurityOwner[] memory);
    function listSecurityHoldings(uint128 securityId) public view returns (HoldingData[] memory);
    function listOwnerHoldings(address owner) public view returns (HoldingData[] memory);
    function decimals() public view virtual returns (uint8);
    function totalSupply(uint128 securityId) public view virtual returns (uint256);
    function balanceOf(uint128 securityId, address account) public view virtual returns (uint256);

    event Transfer(uint128 securityId, address indexed from, address indexed to, uint256 value);
}
