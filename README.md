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
3. `*.json`: input data for each transaction (not used by the CI)
4. `*_out.json`: signed transaction, already sent to the testnet
5. `transfer_ownership_back*`: ownership transferred back to the previous owner 
6. `foundry.toml` and `src/`: copied from https://github.com/LuganoPlanB/swissledger-merkle, used by the CI
7. `test/run.sh`: script run by the workflow. It signs and sends the transactions and checks the result
8. `.github/workflows/test.yml`: workflow for Github Actions

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

## CI 
`test.yml` has two jobs: both deploy the contract and run `test/run.sh` (it tests adding and removing a root updater, setting the active root and transferring the ownership).
1. `unit`: runs on every push, on a local anvil chain
2. `smoke`: runs only when started by hand, using "Run workflow", after `unit` passed. It uses the SwissLedger testnet and needs a secret called `WALLET1_KEY`.
