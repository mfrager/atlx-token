// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../libraries/DataMockOracle.sol";
import "../../libraries/ReentrancyGuard.sol";
import "../../libraries/AccessControlEnumerable.sol";
import "../../utils/Context.sol";

contract MockOracle is Context, ReentrancyGuard, AccessControlEnumerable {

    bytes32 public constant TOKEN_ORACLE_ADMIN_ROLE = keccak256("TOKEN_ORACLE_ADMIN_ROLE");

    //event RegisterToken(address indexed token, string label);
    //event RegisterSwapPair(uint32 indexed pair, address indexed fromToken, address indexed toToken, uint256 fromRate, uint256 toRate);
    //event SwapTokens(address indexed fromAccount, uint32 pair, uint256 fromAmount, uint256 toAmount);

    function setupOracle(address admin) external nonReentrant returns (bool) {
        DataTokenSwap storage s = DataTokenSwapStorage.diamondStorage();
        require(!s.setupDone, "SETUP_ALREADY_DONE");
        s.setupDone = true;
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setRoleAdmin(TOKEN_ORACLE_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        _setupRole(TOKEN_ORACLE_ADMIN_ROLE, admin);
    }

    function latestAnswer() external view returns (int256) {
        return(229300601270);
    }
}
