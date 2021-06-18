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
            token1.transfer.signature,
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
            token2.transfer.signature,
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
        ]]
    ], ZERO_ADDRESS, bytes(), {'from': accounts[0]})
    print('Diamond 3: {}'.format(dm3))

    erc1 = interface.IERC20Full(dm1)
    erc2 = interface.IERC20Full(dm2)
    tswp = interface.ITokenSwap(dm3)

    #input('Begin?')

    print('Setup')
    print(erc1.setupERC20Token('Atellix', 'ATLX', 10000000, {'from': accounts[0]}))
    print(erc2.setupERC20Token('Market Intelligence Token', 'MKIT', 10000000, {'from': accounts[0]}))
#    print('Transfer')
#    print(erc1.transfer(accounts[1], 500000, {'from': accounts[0]}))
#    print(erc2.transfer(accounts[1], 500000, {'from': accounts[0]}))
#    print('Balance')
#    print(erc1.balanceOf(accounts[1], {'from': accounts[1]}))
#    print(erc2.balanceOf(accounts[1], {'from': accounts[1]}))

    print('Register Tokens')
    print(tswp.registerToken(dm1, 'ATLX', {'from': accounts[1]}))
    print(tswp.registerToken(dm2, 'MKIT', {'from': accounts[1]}))
    print(tswp.registerSwapPair(1, dm1, dm2, 1, 1, {'from': accounts[1]}))

    #print('Run Forever')
    #while True:
    #    pass
    print('Done')

