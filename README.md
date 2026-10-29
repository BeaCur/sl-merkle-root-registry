# MerkleRootRegistry - Zenroom test transactions

Zenroom (Zencode and lua) transactions that call the `MerkleRootRegistry` smart contract on SwissLedger testnet.

## Contract
1. Address: `0x4B2b5E323b14e10526Bd18095d06fcba5D13E123`
2. Testnet: SwissLedger chain 222
3. RPC: `https://testnet-swiss-ledger-rpc.noku.io`
4. Explorer: `https://explorertest.ledger.swiss/`

## Files
1. `swiss_merkle.lua`: Lua library with the "When" for the transactions
2. `*.zen`: Zencode files, one per "When"
3. `*.json`: input data for each transaction
4. `*_out.json`: signed transaction, already sent to the testnet

## How to run
Sign a transaction with Zenroom, using a keyring file with the private key (never commit it):
```
/path/to/zenroom -z -a file.json -k keyring.json -l swiss_merkle.lua file.zen > file_out.json
```
Then send it:
```
swissledger-cast publish --rpc-url https://testnet-swiss-ledger-rpc.noku.io 0x<signed transaction>
```
Always check the nonce first with `swissledger-cast nonce`.
