// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IAtxTokenV1 {
    /**
     * @dev Token initialization function
     */
    function setupAtxTokenV1(string memory name_, string memory symbol_, uint256 amount_) external;

    /**
     * @dev Emitted when a token has moved after a certain amount of time.
     */
    event BalanceLog(address indexed owner, uint256 balanceNew, uint256 balancePrev, uint256 balancePrevLog, uint ts);
}
