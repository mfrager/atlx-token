import sys
import time
from brownie import Diamond, DiamondCut, ERC20Token, TokenSwap, accounts, interface

ZERO_ADDRESS = '0x0000000000000000000000000000000000000000'

def main():

    token1 = ERC20Token.deploy({'from': accounts[0]})
    dcf1 = DiamondCut.deploy({'from': accounts[0]})
    dm1 = Diamond.deploy([
        [dcf1, 0, [dcf1.diamondCut.signature]]
    ], [accounts[0]], {'from': accounts[0]})
    dmd1 = interface.IDiamondCut(dm1)
    dmd1.diamondCut([
        [token1, 0, [
            token1.setupERC20Token.signature,
            token1.swap.signature,
            token1.transfer.signature,
            token1.transferFrom.signature,
            token1.approve.signature,
            token1.balanceOf.signature,
        ]]
    ], ZERO_ADDRESS, bytes(), {'from': accounts[0]})
    print('Diamond 1: {}'.format(dm1))

    token2 = ERC20Token.deploy({'from': accounts[0]})
    dcf2 = DiamondCut.deploy({'from': accounts[0]})
    dm2 = Diamond.deploy([
        [dcf2, 0, [dcf2.diamondCut.signature]]
    ], [accounts[0]], {'from': accounts[0]})
    dmd2 = interface.IDiamondCut(dm2)
    dmd2.diamondCut([
        [token2, 0, [
            token2.setupERC20Token.signature,
            token2.swap.signature,
            token2.transfer.signature,
            token2.transferFrom.signature,
            token2.approve.signature,
            token2.balanceOf.signature,
        ]]
    ], ZERO_ADDRESS, bytes(), {'from': accounts[0]})
    print('Diamond 2: {}'.format(dm2))

    token3 = TokenSwap.deploy({'from': accounts[0]})
    dcf3 = DiamondCut.deploy({'from': accounts[0]})
    dm3 = Diamond.deploy([
        [dcf3, 0, [dcf3.diamondCut.signature]]
    ], [accounts[0]], {'from': accounts[0]})
    dmd3 = interface.IDiamondCut(dm3)
    print(token3.registerToken.signature)
    dmd3.diamondCut([
        [token3, 0, [
            token3.registerToken.signature,
            token3.registerSwapPair.signature,
            token3.depositTokens.signature,
            token3.withdrawTokens.signature,
            token3.swapTokens.signature,
        ]]
    ], ZERO_ADDRESS, bytes(), {'from': accounts[0]})
    print('Diamond 3: {}'.format(dm3))

    erc1 = interface.IERC20Full(dm1)
    erc2 = interface.IERC20Full(dm2)
    tswp = interface.ITokenSwap(dm3)

    #input('Begin?')

    print('Setup')
    print(erc1.setupERC20Token('Atellix', 'ATLX', 10000000, tswp, {'from': accounts[0]}))
    print(erc2.setupERC20Token('Market Intelligence Token', 'MKIT', 10000000, tswp, {'from': accounts[0]}))
    print('Transfer')
    print(erc1.transfer(accounts[1], 1000, {'from': accounts[0]}))
    print(erc1.transfer(accounts[2], 1000, {'from': accounts[0]}))
    print(erc2.transfer(accounts[1], 1000, {'from': accounts[0]}))
    print(erc2.transfer(accounts[2], 1000, {'from': accounts[0]}))
    print('Balance')
    print(erc1.balanceOf(accounts[1], {'from': accounts[1]}))
    print(erc1.balanceOf(accounts[2], {'from': accounts[2]}))
    print(erc2.balanceOf(accounts[1], {'from': accounts[1]}))
    print(erc2.balanceOf(accounts[2], {'from': accounts[2]}))

    print('Approve')
    print(erc1.approve(tswp, 10000, {'from': accounts[0]}))
    print(erc2.approve(tswp, 10000, {'from': accounts[0]}))

    print('Register Tokens')
    print(tswp.registerToken(dm1, 'ATLX', {'from': accounts[0]}))
    print(tswp.registerToken(dm2, 'MKIT', {'from': accounts[0]}))
    print(tswp.registerSwapPair(1, dm1, dm2, 1, 1, {'from': accounts[0]}).events)
    print(tswp.depositTokens(dm1, accounts[0], 10000, {'from': accounts[0]}).events);
    print(tswp.depositTokens(dm2, accounts[0], 10000, {'from': accounts[0]}).events);
    print(tswp.withdrawTokens(dm1, accounts[3], 1000, {'from': accounts[0]}).events);
    print(tswp.withdrawTokens(dm2, accounts[3], 1000, {'from': accounts[0]}).events);

    print('Swap Balances')
    print(erc1.balanceOf(tswp, {'from': accounts[1]}))
    print(erc2.balanceOf(tswp, {'from': accounts[1]}))
    print(erc1.swap(1, 25000, {'from': accounts[1]}).events)
    #print(erc1.approve(tswp, 250, {'from': accounts[1]}).events)
    #print(tswp.swapTokens(1, accounts[1], 250, {'from': accounts[1]}).events)
    print(erc1.balanceOf(tswp, {'from': accounts[1]}))
    print(erc2.balanceOf(tswp, {'from': accounts[1]}))

    print('Balance')
    print(erc1.balanceOf(accounts[1], {'from': accounts[1]}))
    print(erc1.balanceOf(accounts[2], {'from': accounts[2]}))
    print(erc2.balanceOf(accounts[1], {'from': accounts[1]}))
    print(erc2.balanceOf(accounts[2], {'from': accounts[2]}))

    #print('Run Forever')
    #while True:
    #    pass
    print('Done')

