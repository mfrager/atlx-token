// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../libraries/DataTokenSwap.sol";
import "../../libraries/ReentrancyGuard.sol";
import "../../libraries/AccessControlEnumerable.sol";
import "../../interfaces/IERC20.sol";
import "../../interfaces/IERC20Merchant.sol";
import "../../interfaces/IAggregatorInterface.sol";
import "../../utils/Context.sol";

contract TokenSwap is Context, ReentrancyGuard, AccessControlEnumerable {

    bytes32 public constant TOKEN_SWAP_ADMIN_ROLE = keccak256("TOKEN_SWAP_ADMIN_ROLE");
    bytes32 public constant TOKEN_DEPOSIT_ROLE = keccak256("TOKEN_DEPOSIT_ROLE");
    bytes32 public constant TOKEN_WITHDRAW_ROLE = keccak256("TOKEN_WITHDRAW_ROLE");

    event RegisterToken(address indexed token, string label);
    event RegisterSwapPair(uint32 indexed pair, address indexed fromToken, address indexed toToken);
    event SwapTokens(address indexed fromAccount, address indexed toAccount, uint32 pair, uint256 tokensIn, uint256 tokensOut);

    function setupSwap(address admin) external nonReentrant returns (bool) {
        DataTokenSwap storage s = DataTokenSwapStorage.diamondStorage();
        require(!s.setupDone, "SETUP_ALREADY_DONE");
        s.setupDone = true;
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupBans();
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

    function registerSwapPairs(SwapPair[] calldata pairs) external nonReentrant onlyRole(TOKEN_SWAP_ADMIN_ROLE) returns (bool) {
        DataTokenSwap storage s = DataTokenSwapStorage.diamondStorage();
        for (uint256 spIndex; spIndex < pairs.length; spIndex++) {
            require(sp.fromToken == address(0), "DUPLICATE_SWAP_PAIR");
            SwapPair memory inp = pairs[spIndex];
            SwapPair storage sp = s.swapPairs[inp.pairId];
            require(inp.toToken != inp.fromToken, "INVALID_SWAP_SAME_TOKEN");
            require(s.tokenActive[inp.fromToken] == true, "INVALID_FROM_TOKEN");
            require(s.tokenActive[inp.toToken] == true, "INVALID_TO_TOKEN");
            sp.pairId = inp.paidId;
            sp.fromToken = inp.fromToken;
            sp.toToken = inp.toToken;
            sp.fromRate = inp.fromRate;
            sp.toRate = inp.toRate;
            sp.oracleToken = inp.oracleToken;
            sp.oracleDecimals = inp.oracleDecimals;
            sp.merchant = inp.merchant;
            sp.mint = inp.mint;
            sp.burn = inp.burn;
            emit RegisterSwapPair(pairId, fromToken, toToken, fromRate, toRate);
        return (true);
    }

    function depositTokens(address fromToken, address fromAccount, uint256 fromAmount) external payable nonReentrant onlyRole(TOKEN_DEPOSIT_ROLE) returns (bool) {
        DataTokenSwap storage s = DataTokenSwapStorage.diamondStorage();
        require(s.tokenActive[fromToken] == true, "INVALID_FROM_TOKEN");
        if (fromToken == address(1)) {
            require(fromAmount == 0, "INVALID_PARAMETER");
            fromAmount = msg.value;
        } else {
            bool ok = IERC20(fromToken).transferFrom(fromAccount, address(this), fromAmount);
            require(ok == true, "ERC20_TRANSER_FROM_FAILED");
        }
        s.tokenBalances[fromToken] = s.tokenBalances[fromToken] + fromAmount;
        return (true);
    }

    // withdrawTokens - Only for SwapToken owner. Other accounts own the other tokens themselves.
    function withdrawTokens(address forToken, address payable toAccount, uint256 withdrawAmount) external nonReentrant onlyRole(TOKEN_WITHDRAW_ROLE) returns (bool) {
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

    function swapTokens(uint32 pairId, address fromAccount, address payable toAccount, uint256 tokensIn) external payable nonReentrant returns (bool) {
        notBanned();
        return _swap(pairId, fromAccount, toAccount, tokensIn);
    }

    function _swap(uint32 pairId, address fromAccount, address payable toAccount, uint256 tokensIn) internal returns (bool) {
        DataTokenSwap storage s = DataTokenSwapStorage.diamondStorage();
        SwapPair storage sp = s.swapPairs[pairId];
        require(sp.fromToken != address(0), "INVALID_SWAP_PAIR");
        require(sp.toRate != 0, "SWAP_DISABLED");
        if (sp.fromToken == address(1)) { // buy tokens with Ethereum
            require(tokensIn == 0, "INVALID_PARAMETER");
            require(fromAccount == _msgSender(), "FROM_NOT_SENDER");
            tokensIn = msg.value;
        }
        require(tokensIn >= sp.minimumIn, "BELOW_MINIMUM");
        // Calculate swap rate
        uint256 tokensOut;
        if (sp.oracleToken != address(0)) {
            uint256 oracleQuote = IAggregatorInterface(sp.oracleToken).latestAnswer();
            if (sp.oracleDecimals != 18) { // Scale to 18 decimals if something different
                oracleQuote = oracleQuote * (10**(18 - sp.oracleDecimals));
            } 
            if (sp.oracleInverse) {
                tokensOut = tokensIn * sp.swapRate;
                tokensOut = tokensOut / oracleQuote;
            } else {
                tokensOut = tokensIn * oracleQuote;
                tokensOut = tokensOut / sp.swapRate;
            }
        } else {
            tokensOut = tokensIn * sp.swapRate;
            tokensOut = tokensOut / sp.baseRate;
        }
        // TODO: lockbox adjustment
        if (!sp.mint) {
            require(s.tokenBalances[sp.toToken] >= tokensOut, "NOT_ENOUGH_TOKENS_TO_SWAP");
        }
        if (sp.merchant) {
            bool isMerchant = IERC20Merchant(sp.fromToken).isValidMerchant(fromAccount);
            require(isMerchant, "MERCHANT_ONLY_SWAP");
        }
        if (sp.burn) {
            bool ok2 = IERC20(sp.fromToken).burn(fromAccount, tokensIn);
            require(ok2 == true, "ERC20_BURN_FAILED");
        } else {
            if (sp.fromToken != address(1)) {
                bool ok1 = IERC20(sp.fromToken).transferFrom(fromAccount, address(this), tokensIn);
                require(ok1 == true, "ERC20_TRANSER_IN_FAILED");
            }
            s.tokenBalances[sp.fromToken] = s.tokenBalances[sp.fromToken] + tokensIn;
        }
        if (sp.mint) {
            bool ok3 = IERC20(sp.toToken).mint(toAccount, tokensOut);
            require(ok3 == true, "ERC20_MINT_FAILED");
        } else {
            s.tokenBalances[sp.toToken] = s.tokenBalances[sp.toToken] - tokensOut;
            if (sp.toToken == address(1)) {
                (bool sent, bytes memory data) = toAccount.call{value: withdrawAmount}("");
                require(sent, "ETHEREUM_SWAP_FAILED");
            } else {
                bool ok4 = IERC20(sp.toToken).transfer(toAccount, tokensOut);
                require(ok4 == true, "ERC20_TRANSFER_FAILED");
            }
        }
        emit SwapTokens(fromAccount, toAccount, pairId, tokensIn, tokensOut);
        return (true);
    }
}
