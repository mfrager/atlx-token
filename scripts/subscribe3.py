import sys
import time
import uuid
import sha3
import pprint
from datetime import datetime, timezone
from dateutil.relativedelta import relativedelta
from brownie import Diamond, DiamondCut, ERC20Token, TokenSwap, accounts, interface
from eth_account import Account
from eip712.messages import EIP712Message

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

    # accounts[0] - Circulating Stablecoin Owner
    # accounts[1] - Internal Stablecoin Owner
    # accounts[2] - Revenue
    # accounts[3] - User
    # accounts[4] - Circulating Stablecoin Admin
    # accounts[5] - Internal Stablecoin Admin

    for i in range(6):
        print('Account {}: {}'.format(i, accounts[i]))

    dcf1 = DiamondCut.deploy({'from': accounts[0]})
    dm1 = Diamond.deploy(dcf1, [accounts[0], accounts[4]], {'from': accounts[0]})
    token1 = ERC20Token.deploy({'from': accounts[0]}) # Circulating Stablecoin
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

    dcf2 = DiamondCut.deploy({'from': accounts[1]})
    dm2 = Diamond.deploy(dcf2, [accounts[1], accounts[5]], {'from': accounts[1]})
    token2 = ERC20Token.deploy({'from': accounts[1]}) # Internal Stablecoin
    dmd2 = interface.IDiamondCut(dm2)
    dmd2.diamondCut([
        [token2, 0, [
            token2.setupERC20Token.signature,
            token2.name.signature,
            token2.symbol.signature,
            token2.decimals.signature,
            token2.totalSupply.signature,
            token2.balanceOf.signature,
            token2.transfer.signature,
            token2.transferFrom.signature,
            token2.allowance.signature,
            token2.approve.signature,
            token2.increaseAllowance.signature,
            token2.decreaseAllowance.signature,
            token2.mint.signature,
            token2.burn.signature,
            token2.hardCap.signature,
            # Admin tools
            token2.ban.signature,
            token2.unban.signature,
            token2.hasRole.signature,
            token2.getRoleAdmin.signature,
            token2.grantRole.signature,
            token2.revokeRole.signature,
            token2.renounceRole.signature,
            token2.getRoleMember.signature,
            token2.getRoleMemberCount.signature,
            # Revenue and Merchant Account
            token2.enableMerchant.signature,
            token2.disableMerchant.signature,
            token2.enableRevenue.signature,
            token2.isValidMerchant.signature,
            token2.disableRevenue.signature,
            token2.isRevenueAccount.signature,
            # Subscriptions
            token2.actionBatch.signature,
            token2.beginSubscription.signature,
            token2.processSubscription.signature,
            token2.processSubscriptionBatch.signature,
            token2.grantSubscriptionAdmin.signature,
            token2.revokeSubscriptionAdmin.signature,
        ]]
    ], ZERO_ADDRESS, bytes(), {'from': accounts[1]})
    print('Diamond 2: {}'.format(dm2))

    down2 = interface.IDiamondOwner(dm2)
    print('Diamond 2 Owner: {}'.format(down2.owner({'from': accounts[1]})))
    dadm2 = interface.IDiamondAdmin(dm2)
    print('Diamond 2 Admin: {}'.format(dadm2.admin({'from': accounts[1]})))

    dcf3 = DiamondCut.deploy({'from': accounts[1]})
    dm3 = Diamond.deploy(dcf3, [accounts[1], accounts[5]], {'from': accounts[1]})
    token3 = ERC20Token.deploy({'from': accounts[1]}) # Internal Stablecoin
    dmd3 = interface.IDiamondCut(dm3)
    dmd3.diamondCut([
        [token3, 0, [
            token3.setupERC20Token.signature,
            token3.name.signature,
            token3.symbol.signature,
            token3.decimals.signature,
            token3.totalSupply.signature,
            token3.balanceOf.signature,
            token3.transfer.signature,
            token3.transferFrom.signature,
            token3.allowance.signature,
            token3.approve.signature,
            token3.increaseAllowance.signature,
            token3.decreaseAllowance.signature,
            token3.mint.signature,
            token3.burn.signature,
            # Admin tools
            token3.ban.signature,
            token3.unban.signature,
            token3.hasRole.signature,
            token3.getRoleAdmin.signature,
            token3.grantRole.signature,
            token3.revokeRole.signature,
            token3.renounceRole.signature,
            token3.getRoleMember.signature,
            token3.getRoleMemberCount.signature,
            # Merchants
            token3.enableMerchant.signature,
            token3.disableMerchant.signature,
            token3.isValidMerchant.signature,
            # Subscriptions
            token3.actionBatch.signature,
            token3.beginSubscription.signature,
            token3.processSubscription.signature,
            token3.processSubscriptionBatch.signature,
            token3.grantSubscriptionAdmin.signature,
            token3.revokeSubscriptionAdmin.signature,
        ]]
    ], ZERO_ADDRESS, bytes(), {'from': accounts[1]})
    print('Diamond 3: {}'.format(dm3))

    down3 = interface.IDiamondOwner(dm3)
    print('Diamond 3 Owner: {}'.format(down3.owner({'from': accounts[1]})))
    dadm3 = interface.IDiamondAdmin(dm3)
    print('Diamond 3 Admin: {}'.format(dadm3.admin({'from': accounts[1]})))

    dm4 = Diamond.deploy(dcf1, [accounts[1], accounts[5]], {'from': accounts[1]})
    token4 = TokenSwap.deploy({'from': accounts[1]}) # Swapper
    dmd4 = interface.IDiamondCut(dm4)
    dmd4.diamondCut([
        [token4, 0, [
            token4.setupSwap.signature,
            token4.registerToken.signature,
            token4.registerSwapPairs.signature,
            token4.depositTokens.signature,
            token4.withdrawTokens.signature,
            token4.swapTokens.signature,
        ]]
    ], ZERO_ADDRESS, bytes(), {'from': accounts[1]})
    print('Diamond 4: {}'.format(dm4))

    down4 = interface.IDiamondOwner(dm4)
    print('Diamond 4 Owner: {}'.format(down4.owner({'from': accounts[1]})))
    dadm4 = interface.IDiamondAdmin(dm4)
    print('Diamond 4 Admin: {}'.format(dadm4.admin({'from': accounts[1]})))

    erc1 = interface.IERC20Full(dm1)
    erc2 = interface.IERC20Full(dm2)
    erc3 = interface.IERC20Full(dm3)
    tswp = interface.ITokenSwap(dm4)

    #input('Begin?')

    print('Setup')
    print(erc1.setupERC20Token('Who Dai', 'whoDAI', 1000 * (10**18), 0, tswp, {'from': accounts[0]}).events)
    print(erc2.setupERC20Token('Virtual USD', 'vtUSD', 0, 0, tswp, {'from': accounts[1]}).events)
    print(erc3.setupERC20Token('Atellix', 'ATLX', 10000 * (10**18), 10000000 *(10**18), tswp, {'from': accounts[1]}).events)

    if True:
        print('Transfer')
        print(erc1.transfer(accounts[3], 1000 * (10**18), {'from': accounts[0]})) # User gets whoDAI from exchange

        print('Balance')
        print('User whoDAI: {}'.format(erc1.balanceOf(accounts[3], {'from': accounts[3]}) / (10**18)))
        print('User ATLX: {}'.format(erc2.balanceOf(accounts[3], {'from': accounts[3]}) / (10**18)))
        print('Swap whoDAI: {}'.format(erc1.balanceOf(tswp, {'from': accounts[1]}) / (10**18)))
        print('Swap ATLX: {}'.format(erc2.balanceOf(tswp, {'from': accounts[1]}) / (10**18)))
        #print('Revenue sDAI: {}'.format(erc1.balanceOf(accounts[2], {'from': accounts[2]}) / (10**18)))
        #print('Revenue vUSD: {}'.format(erc2.balanceOf(accounts[2], {'from': accounts[2]}) / (10**18)))

    if True:
        print('Register Tokens')
        print(tswp.setupSwap(accounts[1], accounts[1], {'from': accounts[1]}))
        print(tswp.registerToken(ONE_ADDRESS, 'ETH', {'from': accounts[1]}))
        print(tswp.registerToken(dm1, 'whoDAI', {'from': accounts[1]}))
        print(tswp.registerToken(dm2, 'vtUSD', {'from': accounts[1]}))
        print(tswp.registerToken(dm3, 'ATLX', {'from': accounts[1]}))
        print(tswp.registerSwapPairs([
            # vtUSD <-> whoDAI
            [1, dm1, dm2, (10**18), (10**18), 50 * (10**18), 0, ZERO_ADDRESS, 0, False, False, True, False],
            [2, dm2, dm1, 0.9 * (10**18), (10**18), 25 * (10**18), 0.025 * (10**18), ZERO_ADDRESS, 0, False, False, False, True],
            [3, dm2, dm1, (10**18), (10**18), 0.01 * (10**18), 0, ZERO_ADDRESS, 0, False, True, False, True], # Merchant-only swap
            # ATLX <-> whoDAI
            [4, dm1, dm3, (10**18), 100 * (10**18), 2 * (10**18), 0, ZERO_ADDRESS, 0, False, False, False, False],
            [5, dm3, dm1, 0.99 * 100 * (10**18), (10**18), 0.5 * (10**18), 0, ZERO_ADDRESS, 0, False, False, False, False],
            # ATLX <-> ETH
        ], {'from': accounts[1]}).events)

        print('Approve')
        print(erc3.approve(tswp, 1000000 * (10**18), {'from': accounts[1]})) # Approve 
        print('Deposit')
        print(tswp.depositTokens(dm3, accounts[1], 1000 * (10**18), {'from': accounts[1]}).events); # Deposit all of owner's SaaS Coins

        #print(tswp.registerSwapPair(1, dm1, dm2, 1, 1, False, {'from': accounts[1]}).events)
        #print(tswp.registerSwapPair(2, dm2, dm1, 0.9 * (10**10), (10**10), False, {'from': accounts[1]}).events)
        #print(tswp.registerSwapPair(3, dm2, dm1, 1, 1, True, {'from': accounts[1]}).events)
        #print(tswp.registerSwapPair(4, ONE_ADDRESS, dm2, 2000 * (10**18), (10**18), False, {'from': accounts[1]}).events)

    if True:
        print('Approve')
        print(erc1.approve(tswp, 500 * (10**18), {'from': accounts[3]}))
        #print(tswp.swapTokens(4, accounts[3], accounts[3], 100 * (10**18), {'from': accounts[3]}))

        print('Enable Merchant 1')
        print(erc2.enableMerchant(accounts[2], {'from': accounts[1]}).events)

        print('Authorize Admin 1')
        print(erc2.grantRole(sha3.keccak_256(b'REVENUE_ADMIN_ROLE').digest(), '0xd4039eB67CBB36429Ad9DD30187B94f6A5122215', {'from': accounts[1]}).events)

        print('Action Batch')
        sbid = uuid.uuid4().bytes
        fid = uuid.uuid4().bytes
        #fid_hash = sha3.keccak_256(fid).digest()

        class SignedTransfer(EIP712Message):
            _name_: 'string' = 'vtUSD'
            _version_: 'string' = '1'
            _chainId_: 'uint256' = 0
            _verifyingContract_: 'address' = str(dm2)
            exp: 'uint64' # expires
            src: 'address' # source
            tid: 'uint128'  # transfer id

        local = Account.from_key('0x64e02814da99b567a92404a5ac82c087cd41b0065cd3f4c154c14130f1966aaf') # Account 1
        expire = int(time.time()) + 60
        sid = SignedTransfer(exp=expire, src=str(accounts[3]), tid=int.from_bytes(fid, 'big'))
        sm = local.sign_message(sid)
        #print(sm.messageHash.hex())
        
        print(erc2.actionBatch(accounts[3], [0, 1], [
            [tswp, accounts[3], 1, 100 * (10**18)], # Swap
        ], [
            [sbid, accounts[2], False, True, fid, 25 * (10**18), ts_data(), [3, 60 * 60 * 48, 50 * (10**18)]], # Subscribe
        ], [fid, expire, sm.signature], {'from': accounts[3]}).events) # batch action

        print('Balance')
        print('User whoDAI: {}'.format(erc1.balanceOf(accounts[3], {'from': accounts[3]}) / (10**18)))
        print('User vtUSD: {}'.format(erc2.balanceOf(accounts[3], {'from': accounts[3]}) / (10**18)))
        print('User ATLX: {}'.format(erc3.balanceOf(accounts[3], {'from': accounts[3]}) / (10**18)))
        print('Swap whoDAI: {}'.format(erc1.balanceOf(tswp, {'from': accounts[1]}) / (10**18)))
        print('Swap vtUSD: {}'.format(erc2.balanceOf(tswp, {'from': accounts[1]}) / (10**18)))
        print('Swap ATLX: {}'.format(erc3.balanceOf(tswp, {'from': accounts[1]}) / (10**18)))

    if False:
        print(erc3.approve(tswp, 1 * (10**18), {'from': accounts[3]}))
        print(tswp.swapTokens(5, accounts[3], accounts[3], 1 * (10**18), {'from': accounts[3]}))

        print('Balance')
        print('User whoDAI: {}'.format(erc1.balanceOf(accounts[3], {'from': accounts[3]}) / (10**18)))
        print('User vtUSD: {}'.format(erc2.balanceOf(accounts[3], {'from': accounts[3]}) / (10**18)))
        print('User ATLX: {}'.format(erc3.balanceOf(accounts[3], {'from': accounts[3]}) / (10**18)))
        print('Swap whoDAI: {}'.format(erc1.balanceOf(tswp, {'from': accounts[1]}) / (10**18)))
        print('Swap vtUSD: {}'.format(erc2.balanceOf(tswp, {'from': accounts[1]}) / (10**18)))
        print('Swap ATLX: {}'.format(erc3.balanceOf(tswp, {'from': accounts[1]}) / (10**18)))

    if False:
        #print(tswp.depositTokens(dm1, accounts[3], 100, {'from': accounts[3]}).events); # Deposit 100 VUSD by User to swap for SAAS

        print('Approve 2')
        print(erc1.approve(tswp, 1000 * (10**18), {'from': accounts[3]})) # Approve purchase of SaaS Coin

        #print('Action')
        #print(erc2.actionBatch([0], [
        #    [tswp, 1, 500], # Swap
        #], [], {'from': accounts[3]}).events) # batch action

        sbid = uuid.uuid4().bytes
        fid = uuid.uuid4().bytes
        print(erc2.actionBatch(accounts[3], [0, 1], [
            [tswp, accounts[3], 1, 500 * (10**18)], # Swap
        ], [
            [sbid, accounts[2], False, True, fid, 10 * (10**18), ts_data(), [3, 60 * 60 * 48, 100 * (10**18)]], # Subscribe
        ], {'from': accounts[1]}).events) # batch action

        #print('Swap')
        #print(tswp.swapTokens(1, accounts[3], 100, {'from': accounts[3]}).events); # SAAS owner swaps User's VUSD for SAAS

        #print('Buy')
        #print(tswp.buyTokens(4, {'from': accounts[3], 'value': (3*(10**18))}).events); # SAAS owner swaps User's VUSD for SAAS
        #print(tswp.withdrawTokens(ONE_ADDRESS, accounts[3], 1**(10**18), {'from': accounts[1]}).events);

        print('Balance')
        print('User sDAI: {}'.format(erc1.balanceOf(accounts[3], {'from': accounts[3]}) / (10**18)))
        print('User vUSD: {}'.format(erc2.balanceOf(accounts[3], {'from': accounts[3]}) / (10**18)))
        print('Swap sDAI: {}'.format(erc1.balanceOf(tswp, {'from': accounts[1]}) / (10**18)))
        print('Swap vUSD: {}'.format(erc2.balanceOf(tswp, {'from': accounts[1]}) / (10**18)))
        print('Revenue sDAI: {}'.format(erc1.balanceOf(accounts[2], {'from': accounts[2]}) / (10**18)))
        print('Revenue vUSD: {}'.format(erc2.balanceOf(accounts[2], {'from': accounts[2]}) / (10**18)))

    if False:
        print('Swaps')
        print(erc2.approve(tswp, 100 * (10**18), {'from': accounts[3]})) # Approve 
        print(tswp.swapTokens(2, accounts[3], 100 * (10**18), {'from': accounts[3]}).events)

        print(erc2.approve(tswp, 10 * (10**18), {'from': accounts[2]})) # Approve 
        print(tswp.swapTokens(3, accounts[2], 10 * (10**18), {'from': accounts[2]}).events)

        print('Balance')
        print('User sDAI: {}'.format(erc1.balanceOf(accounts[3], {'from': accounts[3]}) / (10**18)))
        print('User vUSD: {}'.format(erc2.balanceOf(accounts[3], {'from': accounts[3]}) / (10**18)))
        print('Swap sDAI: {}'.format(erc1.balanceOf(tswp, {'from': accounts[1]}) / (10**18)))
        print('Swap vUSD: {}'.format(erc2.balanceOf(tswp, {'from': accounts[1]}) / (10**18)))
        print('Revenue sDAI: {}'.format(erc1.balanceOf(accounts[2], {'from': accounts[2]}) / (10**18)))
        print('Revenue vUSD: {}'.format(erc2.balanceOf(accounts[2], {'from': accounts[2]}) / (10**18)))

    if False:
        #print('Subscribe')
        #sbid = uuid.uuid4().bytes
        #print(erc2.beginSubscription(sbid, accounts[3], accounts[2], terms1, False, [3, 60 * 60 * 48, 100], {'from': accounts[2]}).events)

        print('Process')
        #evid = uuid.uuid4().bytes
        #print(erc2.processSubscription([sbid, evid, 1, 50, ts_data()], True, {'from': accounts[2]}).events)

        evid2 = uuid.uuid4().bytes
        print(erc2.processSubscription([sbid, evid2, 1, 50, ts_data(relativedelta(months=1))], True, {'from': accounts[1]}).events)

        evid3 = uuid.uuid4().bytes
        print(erc2.processSubscription([sbid, evid3, 1, 50, ts_data(relativedelta(months=2))], True, {'from': accounts[1]}).events)

        #print(erc2.adminTransfer(accounts[3], accounts[2], 200, {'from': accounts[4]}).events)

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

