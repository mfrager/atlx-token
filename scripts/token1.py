import sys
import time
from brownie import Diamond, DiamondCut, ERC20Token, accounts, interface

ZERO_ADDRESS = '0x0000000000000000000000000000000000000000'

def main():

    token = ERC20Token.deploy({'from': accounts[0]})
    dcf = DiamondCut.deploy({'from': accounts[0]})
    dm1 = Diamond.deploy([
        [dcf, 0, [dcf.diamondCut.signature]]
    ], [accounts[0]], {'from': accounts[0]})
    print('Diamond: {}'.format(dm1))

    dmd = interface.IDiamondCut(dm1)
    dmd.diamondCut([
        [token, 0, [
            token.setupERC20Token.signature,
            token.transfer.signature,
            token.balanceOf['address'].signature,
            token.balanceOf['address', 'uint256'].signature,
        ]]
    ], ZERO_ADDRESS, bytes(), {'from': accounts[0]})

    erc = interface.IERC20Full(dm1)

    #input('Begin?')

    print('Setup')
    print(erc.setupERC20Token('Atellix', 'ATLX', 10000000, {'from': accounts[0]}))
    print('Transfer')
    print(erc.transfer(accounts[1], 500000, {'from': accounts[0]}).events)
    print('Balance')
    print(erc.balanceOf(accounts[1], {'from': accounts[1]}))

    #print('Run Forever')
    #while True:
    #    pass
    print('Done')
