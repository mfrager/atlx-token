import sys
import time
import uuid
from datetime import datetime, timezone
from brownie import Diamond, DiamondCut, ERC20Token, SubscriptionTerms, accounts, interface

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
            #token1.swap.signature,
            token1.transfer.signature,
            token1.transferFrom.signature,
            token1.approve.signature,
            token1.balanceOf.signature,
            token1.beginSubscription.signature,
            token1.processSubscription.signature,
            token1.processSubscriptionBatch.signature,
        ]]
    ], ZERO_ADDRESS, bytes(), {'from': accounts[0]})
    print('Diamond 1: {}'.format(dm1))

    erc1 = interface.IERC20Full(dm1)

    terms1 = SubscriptionTerms.deploy({'from': accounts[1]});

    def ts_data():
        ts = time.time()
        dt = datetime.fromtimestamp(ts).replace(tzinfo=timezone.utc)
        yrs = dt.strftime('%Y').encode('utf8')[:4]
        q = str(((dt.month - 1) // 3) + 1).encode('utf8')
        qtr = dt.strftime('%Y').encode('utf8')[:4] + q
        mth = dt.strftime('%Y%m').encode('utf8')[:6]
        w = str(dt.isocalendar()[1]).zfill(2).encode('utf8')[:2]
        wkn = dt.strftime('%Y').encode('utf8')[:4] + w
        day = dt.strftime('%Y%m%d').encode('utf8')[:8]
        res = [int(ts), yrs, qtr, mth, wkn, day]
        print('TS Data: {}'.format(res))
        return res

    #input('Begin?')

    print('Setup')
    print(erc1.setupERC20Token('Atellix', 'ATLX', 10000000, ZERO_ADDRESS, {'from': accounts[0]}))
    print('Transfer')
    print(erc1.transfer(accounts[1], 1000, {'from': accounts[0]}))
    print('Balance')
    print(erc1.balanceOf(accounts[1], {'from': accounts[1]}))
    print('Subscribe')
    sbid = uuid.uuid4().bytes
    print(erc1.beginSubscription(sbid, accounts[1], accounts[2], terms1, False, [0, 60 * 60 * 48, 51], {'from': accounts[1]}).events)
    print('Process')
    evid = uuid.uuid4().bytes
    print(erc1.processSubscription([sbid, evid, 1, 50, ts_data()], True, {'from': accounts[2]}).events)
    evid2 = uuid.uuid4().bytes
    print(erc1.processSubscription([sbid, evid2, 1, 50, ts_data()], True, {'from': accounts[2]}).events)
    print('Balance')
    print(erc1.balanceOf(accounts[1], {'from': accounts[1]}))
    print(erc1.balanceOf(accounts[2], {'from': accounts[2]}))

    #print('Run Forever')
    #while True:
    #    pass
    print('Done')

