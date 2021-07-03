import sys
import time
import uuid
from datetime import datetime, timezone
from dateutil.relativedelta import relativedelta
from brownie import Diamond, DiamondCut, ERC20Token, TokenSwap, SubscriptionTerms, accounts, interface

ZERO_ADDRESS = '0x0000000000000000000000000000000000000000'

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
    res = [int(ts), yrs, qtr, mth, wkn, day]
    print('TS Data: {}'.format(res))
    return res

def main():

    # accounts[0] - Circulating Stablecoin Owner
    # accounts[1] - Internal Stablecoin Owner
    # accounts[2] - Revenue
    # accounts[3] - User
    # accounts[4] - Circulating Stablecoin Admin
    # accounts[5] - Internal Stablecoin Admin

    token1 = ERC20Token.deploy({'from': accounts[0]}) # Circulating Stablecoin
    dcf1 = DiamondCut.deploy({'from': accounts[0]})
    dm1 = Diamond.deploy([
        [dcf1, 0, [
            dcf1.diamondCut.signature,
            dcf1.transferOwnership.signature,
            dcf1.transferAdministrator.signature,
            dcf1.owner.signature,
            dcf1.admin.signature,
        ]]
    ], [accounts[0], accounts[4]], {'from': accounts[0]})
    dmd1 = interface.IDiamondCut(dm1)
    dmd1.diamondCut([
        [token1, 0, [
            token1.setupERC20Token.signature,
            token1.transfer.signature,
            token1.transferFrom.signature,
            token1.approve.signature,
            token1.balanceOf.signature,
        ]]
    ], ZERO_ADDRESS, bytes(), {'from': accounts[0]})
    print('Diamond 1: {}'.format(dm1))

    down1 = interface.IDiamondOwner(dm1)
    print('Diamond 1 Owner: {}'.format(down1.owner({'from': accounts[0]})))
    dadm1 = interface.IDiamondAdmin(dm1)
    print('Diamond 1 Admin: {}'.format(dadm1.admin({'from': accounts[0]})))

    token2 = ERC20Token.deploy({'from': accounts[1]}) # Internal Stablecoin
    dcf2 = DiamondCut.deploy({'from': accounts[1]})
    dm2 = Diamond.deploy([
        [dcf2, 0, [dcf2.diamondCut.signature]]
    ], [accounts[1], accounts[5]], {'from': accounts[1]})
    dmd2 = interface.IDiamondCut(dm2)
    dmd2.diamondCut([
        [token2, 0, [
            token2.setupERC20Token.signature,
            token2.transfer.signature,
            token2.transferFrom.signature,
            token2.approve.signature,
            token2.balanceOf.signature,
            token2.actionBatch.signature,
            token2.beginSubscription.signature,
            token2.processSubscription.signature,
            token2.processSubscriptionBatch.signature,
        ]]
    ], ZERO_ADDRESS, bytes(), {'from': accounts[1]})
    print('Diamond 2: {}'.format(dm2))

    token3 = TokenSwap.deploy({'from': accounts[1]}) # Swapper
    dcf3 = DiamondCut.deploy({'from': accounts[1]})
    dm3 = Diamond.deploy([
        [dcf3, 0, [dcf3.diamondCut.signature]]
    ], [accounts[1], accounts[5]], {'from': accounts[1]})
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
    ], ZERO_ADDRESS, bytes(), {'from': accounts[1]})
    print('Diamond 3: {}'.format(dm3))

    # TODO: Make terms a Diamond
    terms1 = SubscriptionTerms.deploy({'from': accounts[1]});

    erc1 = interface.IERC20Full(dm1)
    erc2 = interface.IERC20Full(dm2)
    tswp = interface.ITokenSwap(dm3)

    #input('Begin?')

    print('Setup')
    print(erc1.setupERC20Token('Virtual USD', 'VUSD', 1000000, tswp, {'from': accounts[0]}))
    print(erc2.setupERC20Token('SaaS Coin', 'SAAS', 1000000, tswp, {'from': accounts[1]}))
    print('Transfer')
    print(erc1.transfer(accounts[3], 1000, {'from': accounts[0]})) # User gets VUSD from exchange
    #print(erc2.transfer(accounts[1], 1000000, {'from': accounts[1]})) # Transfer owner all minted SaaS Coin


    print('Balance')
    print('User VUSD: {}'.format(erc1.balanceOf(accounts[3], {'from': accounts[3]})))
    print('User SAAS: {}'.format(erc2.balanceOf(accounts[3], {'from': accounts[3]})))
    print('Owner SAAS: {}'.format(erc2.balanceOf(accounts[1], {'from': accounts[1]})))
    print('Swap SAAS: {}'.format(erc2.balanceOf(tswp, {'from': accounts[1]})))


    print('Register Tokens')
    print(tswp.registerToken(dm1, 'VUSD', {'from': accounts[1]}))
    print(tswp.registerToken(dm2, 'SAAS', {'from': accounts[1]}))
    print(tswp.registerSwapPair(1, dm1, dm2, 1, 1, {'from': accounts[1]}).events)

    print('Approve 1')
    print(erc2.approve(tswp, 1000000, {'from': accounts[1]})) # Approve 
    print('Deposit')
    print(tswp.depositTokens(dm2, accounts[1], 1000000, {'from': accounts[1]}).events); # Deposit all of owner's SaaS Coins
    #print(tswp.depositTokens(dm1, accounts[3], 100, {'from': accounts[3]}).events); # Deposit 100 VUSD by User to swap for SAAS

    print('Approve 2')
    print(erc1.approve(tswp, 1000, {'from': accounts[3]})) # Approve purchase of SaaS Coin

    print('Action')
    sbid = uuid.uuid4().bytes
    fid = uuid.uuid4().bytes
    print(erc2.actionBatch([0, 1], [
        [tswp, 1, 1000], # Swap
    ], [
        [sbid, terms1, accounts[2], False, True, fid, 10, ts_data(), [3, 60 * 60 * 48, 100]], # Subscribe
    ], {'from': accounts[3]}).events) # batch action

    #print('Swap')
    #print(tswp.swapTokens(1, accounts[3], 100, {'from': accounts[3]}).events); # SAAS owner swaps User's VUSD for SAAS
    #print(tswp.withdrawTokens(dm2, accounts[3], 100, {'from': accounts[1]}).events);

    print('Balance')
    print('User VUSD: {}'.format(erc1.balanceOf(accounts[3], {'from': accounts[3]})))
    print('User SAAS: {}'.format(erc2.balanceOf(accounts[3], {'from': accounts[3]})))
    print('Swap VUSD: {}'.format(erc1.balanceOf(tswp, {'from': accounts[1]})))
    print('Swap SAAS: {}'.format(erc2.balanceOf(tswp, {'from': accounts[1]})))
    print('Revenue SAAS: {}'.format(erc2.balanceOf(accounts[2], {'from': accounts[2]})))

    if False:
        print('Subscribe')
        sbid = uuid.uuid4().bytes
        print(erc2.beginSubscription(sbid, accounts[3], accounts[2], terms1, False, [3, 60 * 60 * 48, 100], {'from': accounts[2]}).events)

        print('Process')
        evid = uuid.uuid4().bytes
        print(erc2.processSubscription([sbid, evid, 1, 50, ts_data()], True, {'from': accounts[2]}).events)

        evid2 = uuid.uuid4().bytes
        print(erc2.processSubscription([sbid, evid2, 1, 50, ts_data(relativedelta(months=1))], True, {'from': accounts[2]}).events)

        #evid3 = uuid.uuid4().bytes
        #print(erc2.processSubscription([sbid, evid3, 1, 50, ts_data(relativedelta(months=2))], True, {'from': accounts[2]}).events)

        print('Balance')
        print('User VUSD: {}'.format(erc1.balanceOf(accounts[3], {'from': accounts[3]})))
        print('User SAAS: {}'.format(erc2.balanceOf(accounts[3], {'from': accounts[3]})))
        print('Owner SAAS: {}'.format(erc2.balanceOf(accounts[1], {'from': accounts[1]})))
        print('Swap SAAS: {}'.format(erc2.balanceOf(tswp, {'from': accounts[1]})))
        print('Swap VUSD: {}'.format(erc1.balanceOf(tswp, {'from': accounts[1]})))
        print('Revenue SAAS: {}'.format(erc2.balanceOf(accounts[2], {'from': accounts[2]})))

    #print('Run Forever')
    #while True:
    #    pass
    print('Done')

