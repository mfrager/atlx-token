import sys
import time
import uuid
import sha3
import pprint
from datetime import datetime, timezone
from dateutil.relativedelta import relativedelta
from brownie import Diamond, DiamondCut, MockOracle, accounts, interface
from eth_account import Account
from eip712.messages import EIP712Message

ZERO_ADDRESS = '0x0000000000000000000000000000000000000000'
ONE_ADDRESS = '0x0000000000000000000000000000000000000001'

def main():

    # accounts[0] - Circulating Stablecoin Owner
    # accounts[1] - Internal Stablecoin Owner
    # accounts[2] - Revenue
    # accounts[3] - User
    # accounts[4] - Circulating Stablecoin Admin
    # accounts[5] - Internal Stablecoin Admin

    for i in range(6):
        print('Account {}: {}'.format(i, accounts[i]))

#    dcf5 = DiamondCut.deploy({'from': accounts[1]})
#    dm5 = Diamond.deploy(dcf5, [accounts[1], accounts[5]], {'from': accounts[1]})
#    token5 = MockOracle.deploy({'from': accounts[1]}) # Mock Oracle
#    dmd5 = interface.IDiamondCut(dm5)
#    dmd5.diamondCut([
#        [token5, 0, [
#            token5.setupOracle.signature,
#            token5.latestAnswer.signature,
#        ]]
#    ], ZERO_ADDRESS, bytes(), {'from': accounts[1]})
#    print('Diamond 5 (Mock Oracle): {}'.format(dm5))
#
#    down5 = interface.IDiamondOwner(dm5)
#    print('Diamond 5 Owner: {}'.format(down5.owner({'from': accounts[1]})))
#    dadm5 = interface.IDiamondAdmin(dm5)
#    print('Diamond 5 Admin: {}'.format(dadm5.admin({'from': accounts[1]})))

    dm5 = '0xC9906c7Ccc41987623d0E4903ccEF7973b0b0f72'
    torc = interface.IMockOracle(dm5)
    vusd = interface.IERC20Full('0x132145408A9694ee8ab7302E3eEa4be8Dc46fe4f')
    tswp = interface.ITokenSwap('0xA3aBD9bE44A0Daae52BED5EBA7D7Cd8a5B0fA901')

    torc.setupOracle(accounts[5], {'from': accounts[1]})

    #input('Begin?')

    if True:
        print('Register Tokens')
        print(tswp.registerSwapPairs([
            # vtUSD <-> whoDAI
            #[1, dm1, dm2, (10**18), (10**18), 50 * (10**18), 0, ZERO_ADDRESS, 0, False, False, True, False],
            #[2, dm2, dm1, 0.9 * (10**18), (10**18), 25 * (10**18), 0.025 * (10**18), ZERO_ADDRESS, 0, False, False, False, True],
            #[3, dm2, dm1, (10**18), (10**18), 0.01 * (10**18), 0, ZERO_ADDRESS, 0, False, True, False, True], # Merchant-only swap
            # ATLX <-> whoDAI
            #[4, dm1, dm3, (10**18), 100 * (10**18), 2 * (10**18), 0, ZERO_ADDRESS, 0, False, False, False, False],
            #[5, dm3, dm1, 0.99 * 100 * (10**18), (10**18), 0.5 * (10**18), 0, ZERO_ADDRESS, 0, False, False, False, False],
            # vtUSD <-> ETH
            [6, ONE_ADDRESS, vusd, (10**18), (10**18), 0.0025 * (10**18), 0, torc, 8, False, False, True, False],
            [7, vusd, ONE_ADDRESS, 0.9 * (10**18), (10**18), 50 * (10**18), 0, torc, 8, True, False, False, True],
        ], {'from': accounts[1]}).events)

    print('Done')

