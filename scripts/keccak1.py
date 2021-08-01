import sha3
#print(sha3.keccak_256('Permit(address holder,address spender,uint256 nonce,uint256 expiry,bool allowed)'.encode('utf8')).hexdigest())
#print(sha3.keccak_256('SignedId(bytes32 hash)'.encode('utf8')).hexdigest())
print(sha3.keccak_256('SignedTransfer(uint64 exp,address src,uint128 tid)'.encode('utf8')).hexdigest())
#print(sha3.keccak_256('REVENUE_ADMIN_ROLE'.encode('utf8')).hexdigest())
