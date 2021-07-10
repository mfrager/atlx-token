// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../libraries/DataTokenSwap.sol";
import "../../libraries/ReentrancyGuard.sol";
import "../../libraries/AccessControlEnumerable.sol";
import "../../interfaces/IERC20.sol";
import "../../interfaces/IERC20Merchant.sol";
import "../../utils/Context.sol";

contract TokenSwap is Context, ReentrancyGuard, AccessControlEnumerable {

    bytes32 public constant TOKEN_SWAP_ADMIN_ROLE = keccak256("TOKEN_SWAP_ADMIN_ROLE");
    bytes32 public constant TOKEN_DEPOSIT_ROLE = keccak256("TOKEN_DEPOSIT_ROLE");
    bytes32 public constant TOKEN_WITHDRAW_ROLE = keccak256("TOKEN_WITHDRAW_ROLE");

    event RegisterToken(address indexed token, string label);
    event RegisterSwapPair(uint32 indexed pair, address indexed fromToken, address indexed toToken, uint256 fromRate, uint256 toRate);
    event SwapTokens(address indexed fromAccount, uint32 pair, uint256 fromAmount, uint256 toAmount);

    function setupSwap(address admin) external nonReentrant returns (bool) {
        DataTokenSwap storage s = DataTokenSwapStorage.diamondStorage();
        require(!s.setupDone, "SETUP_ALREADY_DONE");
        s.setupDone = true;
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setRoleAdmin(TOKEN_SWAP_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(TOKEN_DEPOSIT_ROLE, DEFAULT_ADMIN_ROLE);
        _setRoleAdmin(TOKEN_WITHDRAW_ROLE, DEFAULT_ADMIN_ROLE);
        _setupRole(TOKEN_SWAP_ADMIN_ROLE, admin);
        _setupRole(TOKEN_DEPOSIT_ROLE, admin);
        _setupRole(TOKEN_WITHDRAW_ROLE, admin);
    }

    function registerToken(address tokenContract, string memory label) external nonReentrant onlyRole(TOKEN_SWAP_ADMIN_ROLE) returns (bool) {
        DataTokenSwap storage s = DataTokenSwapStorage.diamondStorage();
        bytes32 lookupHash = keccak256(abi.encode(label));
        require(s.tokenLookup[lookupHash] == address(0), "DUPLICATE_TOKEN");
        s.tokenLookup[lookupHash] = tokenContract;
        s.tokenActive[tokenContract] = true;
        emit RegisterToken(tokenContract, label);
        return (true);
    }

    function registerSwapPair(uint32 pairId, address fromToken, address toToken, uint256 fromRate, uint256 toRate, bool merchant) external nonReentrant onlyRole(TOKEN_SWAP_ADMIN_ROLE) returns (bool) {
        DataTokenSwap storage s = DataTokenSwapStorage.diamondStorage();
        SwapPair storage sp = s.swapPairs[pairId];
        // require(sp.fromToken == address(0), "DUPLICATE_SWAP_PAIR");
        require(toToken != fromToken, "INVALID_SWAP_SAME_TOKEN");
        require(s.tokenActive[fromToken] == true, "INVALID_FROM_TOKEN");
        require(s.tokenActive[toToken] == true, "INVALID_TO_TOKEN");
        sp.fromToken = fromToken;
        sp.toToken = toToken;
        sp.fromRate = fromRate;
        sp.toRate = toRate;
        sp.merchant = merchant;
        emit RegisterSwapPair(pairId, fromToken, toToken, fromRate, toRate);
        return (true);
    }

    function depositTokens(address fromToken, address fromAccount, uint256 fromAmount) external nonReentrant onlyRole(TOKEN_DEPOSIT_ROLE) returns (bool) {
        DataTokenSwap storage s = DataTokenSwapStorage.diamondStorage();
        require(s.tokenActive[fromToken] == true, "INVALID_FROM_TOKEN");
        bool ok = IERC20(fromToken).transferFrom(fromAccount, address(this), fromAmount);
        require(ok == true, "ERC20_TRANSER_FROM_FAILED");
        s.tokenBalances[fromToken] = s.tokenBalances[fromToken] + fromAmount;
        return (true);
    }

    // withdrawTokens - Only for SwapToken owner. Other accounts own the other tokens themselves.
    function withdrawTokens(address forToken, address toAccount, uint256 withdrawAmount) external nonReentrant onlyRole(TOKEN_WITHDRAW_ROLE) returns (bool) {
        DataTokenSwap storage s = DataTokenSwapStorage.diamondStorage();
        require(s.tokenActive[forToken] == true, "INVALID_TO_TOKEN");
        require(s.tokenBalances[forToken] >= withdrawAmount, "NOT_ENOUGH_TOKENS_TO_WITHDRAW");
        if (forToken == address(1)) {
            (bool sent, bytes memory data) = toAccount.call{value: withdrawAmount}("");
            require(sent, "ETHEREUM_WITHDRAWAL_FAILED");
        } else {
            bool ok = IERC20(forToken).transfer(toAccount, withdrawAmount);
            require(ok == true, "ERC20_TRANSER_FAILED");
        }
        s.tokenBalances[forToken] = s.tokenBalances[forToken] - withdrawAmount;
        return (true);
    }

    function buyTokens(uint32 pairId) external payable nonReentrant returns (bool) {
        DataTokenSwap storage s = DataTokenSwapStorage.diamondStorage();
        SwapPair storage sp = s.swapPairs[pairId];
        require(sp.fromToken == address(1), "INVALID_BUY_TOKEN");
        return _swapTokens(pairId, _msgSender(), msg.value);
    }

    function swapTokens(uint32 pairId, address fromAccount, uint256 fromAmount) external nonReentrant returns (bool) {
        return _swapTokens(pairId, fromAccount, fromAmount);
    }

    function _swapTokens(uint32 pairId, address fromAccount, uint256 tokensIn) internal returns (bool) {
        DataTokenSwap storage s = DataTokenSwapStorage.diamondStorage();
        SwapPair storage sp = s.swapPairs[pairId];
        require(sp.fromToken != address(0), "INVALID_SWAP_PAIR");
        require(sp.toRate != 0, "SWAP_DISABLED");
        // Calculate swap rate
        uint256 tokensOut = tokensIn * sp.fromRate;
        tokensOut = tokensOut / sp.toRate;
        require(s.tokenBalances[sp.toToken] >= tokensOut, "NOT_ENOUGH_TOKENS_TO_SWAP");
        if (sp.merchant) {
            bool isMerchant = IERC20Merchant(sp.fromToken).isValidMerchant(fromAccount);
            require(isMerchant, "MERCHANT_ONLY_SWAP");
        }
        if (sp.fromToken != address(1)) {
            bool ok1 = IERC20(sp.fromToken).transferFrom(fromAccount, address(this), tokensIn);
            require(ok1 == true, "ERC20_TRANSER_IN_FAILED");
        }
        s.tokenBalances[sp.fromToken] = s.tokenBalances[sp.fromToken] + tokensIn;
        s.tokenBalances[sp.toToken] = s.tokenBalances[sp.toToken] - tokensOut;
        bool ok2 = IERC20(sp.toToken).transfer(fromAccount, tokensOut);
        require(ok2 == true, "ERC20_TRANSER_OUT_FAILED");
        emit SwapTokens(fromAccount, pairId, tokensIn, tokensOut);
        return (true);
    }
}
