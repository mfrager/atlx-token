import sys
import time
import uuid
from datetime import datetime, timezone
from dateutil.relativedelta import relativedelta
from brownie import Diamond, DiamondCut, SecurityToken, accounts, interface

ZERO_ADDRESS = '0x0000000000000000000000000000000000000000'
ONE_ADDRESS = '0x0000000000000000000000000000000000000001'

def ts_data(interval=None):
    ts = time.time()
    dt = datetime.fromtimestamp(ts).replace(tzinfo=timezone.utc)
    if interval is not None:
        dt = dt + interval
    yrs = dt.strftime('%Y').encode('utf8')[:4]
    q = str(((dt.month - 1) // 3) + 1).encode('utf8')
    qtr = dt.strftime('%Y').encode('utf8')[:4] + q
    mth = dt.strftime('%Y%m').encode('utf8')[:6]
    w = str(dt.isocalendar()[1]).zfill(2).encode('utf8')[:2]
    wkn = dt.strftime('%Y').encode('utf8')[:4] + w
    day = dt.strftime('%Y%m%d').encode('utf8')[:8]
    #res = [int(dt.timestamp()), yrs, qtr, mth, wkn, day]
    res = [int(ts), yrs, qtr, mth, wkn, day]
    print('TS Data: {}'.format(res))
    return res

def main():

    token1 = SecurityToken.deploy({'from': accounts[0]}) # Circulating Stablecoin
    dcf1 = DiamondCut.deploy({'from': accounts[0]})
    dm1 = Diamond.deploy(dcf1, [accounts[0], accounts[1]], {'from': accounts[0]})
    dmd1 = interface.IDiamondCut(dm1)
    dmd1.diamondCut([
        [token1, 0, [
            token1.setupSecurityToken.signature,
            token1.processHoldingEvent.signature,
            token1.listSecurities.signature,
            token1.listSecurityHoldings.signature,
            token1.listOwners.signature,
            token1.listOwnerHoldings.signature,
            #token1.transfer.signature,
            #token1.transferFrom.signature,
            #token1.approve.signature,
            #token1.balanceOf.signature,
        ]]
    ], ZERO_ADDRESS, bytes(), {'from': accounts[0]})
    print('Diamond 1: {}'.format(dm1))

    down1 = interface.IDiamondOwner(dm1)
    print('Diamond 1 Owner: {}'.format(down1.owner({'from': accounts[0]})))
    dadm1 = interface.IDiamondAdmin(dm1)
    print('Diamond 1 Admin: {}'.format(dadm1.admin({'from': accounts[0]})))

    st1 = interface.ISecurityToken(dm1)
    st1.setupSecurityToken({'from': accounts[0]})

    sid = uuid.uuid4().bytes
    hid = uuid.uuid4().bytes
    eid = uuid.uuid4().bytes
    evt = [sid, hid, eid, 0, 100 * (10**18), accounts[0], ZERO_ADDRESS, True, ts_data()]
    print(st1.processHoldingEvent(evt, {'from': accounts[0]}).events)

    print('List Securities')
    sl = st1.listSecurities({'from': accounts[0]})
    print(sl)

    print('List Owner')
    print(st1.listOwners({'from': accounts[0]}))

    print('List Owner Holdings')
    print(st1.listOwnerHoldings(accounts[0], {'from': accounts[0]}))
    

    #print('Run Forever')
    #while True:
    #    pass
    print('Done')

