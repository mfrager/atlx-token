// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

/******************************************************************************\
* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
* EIP-2535 Diamond Standard: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondOwner {
    function owner() external view returns (address owner_);
    function admin() external view returns (address admin_);
    function transferOwnership(address _newOwner) external;
    function transferAdministrator(address _newAdmin) external;
}
