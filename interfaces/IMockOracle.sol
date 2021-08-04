// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMockOracle {
    function setupOracle(address admin) external returns (bool);
    function latestAnswer() external view returns (int256);
}
