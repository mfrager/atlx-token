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

    vusd = interface.IERC20Full('0x132145408A9694ee8ab7302E3eEa4be8Dc46fe4f')

    #input('Begin?')

    if True:
        print('Enable Merchant 1')
        print(vusd.enableMerchant(accounts[2], {'from': accounts[1]}).events)

        print('Authorize Admin 1')
        print(vusd.grantRole(sha3.keccak_256(b'REVENUE_ADMIN_ROLE').digest(), '0xd4039eB67CBB36429Ad9DD30187B94f6A5122215', {'from': accounts[1]}).events)
    print('Done')

