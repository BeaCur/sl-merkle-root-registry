#!/usr/bin/env bash
set -euo pipefail

# generate a temporary dir to put temporary files
TEMP=$(mktemp -d) 
# OWNER_KEY without 0x (zenroom)
O_KEY=${OWNER_KEY#0x}
# get the wallet address (from private key)
ADDR=$(cast wallet address --private-key "$OWNER_KEY")
# retrieve nonce
NONCE=$(cast nonce "$ADDR" --rpc-url "$RPC_URL")
# retrieve gas price
GAS=$(cast gas-price --rpc-url "$RPC_URL")

# the zen file in the repo has chain ID 222 (the testnet) but in anvil is 31337
# (the file is saved in the temporary directory)
sed "s/chain '222'/chain '$CHAIN_ID'/" add_newUpdater.zen > "$TEMP/add_newUpdater.zen"

# Create the keyring and save it in the temporary directory
#echo "{\"ethereum\":\"$O_KEY\"}" > "$TEMP/myKeyring.json"
cat << EOF > "$TEMP/myKeyring.json"
{
    "keyring": {
            "ethereum": "$O_KEY"
    }
}
EOF
# create the input file (json)
cat << EOF > "$TEMP/add_newUpdater.json"
{
    "gas price": "$GAS",
    "gas limit": "300000",
    "ethereum nonce": "$NONCE",
    "contract_address": "$CONTRACT",
    "updater_address": "$UPDATER_ADDR" 
}
EOF
# Sign the transaction
"$ZENROOM" -z -a "$TEMP/add_newUpdater.json" -k "$TEMP/myKeyring.json" -l swiss_merkle.lua "$TEMP/add_newUpdater.zen" > "$TEMP/add_newUpdater_out.json"
# publish the transaction
cast publish --rpc-url "$RPC_URL" "0x$(jq -r .signed_ethereum_transaction "$TEMP/add_newUpdater_out.json")"


# check the result
cast call "$CONTRACT" 'isRootUpdater(address)(bool)' "$UPDATER_ADDR" --rpc-url "$RPC_URL" \
  |grep -q true || { echo "FAIL: updater not registered"; exit 1; }
echo "PASS: addRootUpdater"


# Test "removeRootUpdater"
NONCE=$(cast nonce "$ADDR" --rpc-url "$RPC_URL")
sed "s/chain '222'/chain '$CHAIN_ID'/" remove_updater.zen > "$TEMP/remove_updater.zen"
cat << EOF > "$TEMP/remove_updater.json"
{
    "gas price": "$GAS",
    "gas limit": "300000",
    "ethereum nonce": "$NONCE",
    "contract_address": "$CONTRACT",
    "updater_address": "$UPDATER_ADDR" 
}
EOF
# Sign the transaction
"$ZENROOM" -z -a "$TEMP/remove_updater.json" -k "$TEMP/myKeyring.json" -l swiss_merkle.lua "$TEMP/remove_updater.zen" > "$TEMP/remove_updater_out.json"
# publish the transaction
cast publish --rpc-url "$RPC_URL" "0x$(jq -r .signed_ethereum_transaction "$TEMP/remove_updater_out.json")"
# check the result
cast call "$CONTRACT" 'isRootUpdater(address)(bool)' "$UPDATER_ADDR" --rpc-url "$RPC_URL" \
  |grep -q false || { echo "FAIL: updater still registered"; exit 1; }
echo "PASS: removeRootUpdater"


# Test "setActiveRoot"
NONCE=$(cast nonce "$ADDR" --rpc-url "$RPC_URL")
ROOT="0x0354b09ac3a192e45433a9fa81a366283e230999522af8f8a249f2a1982f6863"
sed "s/chain '222'/chain '$CHAIN_ID'/" set_root.zen > "$TEMP/set_root.zen"
cat << EOF > "$TEMP/set_root.json"
{
    "gas price": "$GAS",
    "gas limit": "300000",
    "ethereum nonce": "$NONCE",
    "contract_address": "$CONTRACT",
    "root": "$ROOT"
}
EOF
"$ZENROOM" -z -a "$TEMP/set_root.json" -k "$TEMP/myKeyring.json" -l swiss_merkle.lua "$TEMP/set_root.zen" > "$TEMP/set_root_out.json"
cast publish --rpc-url "$RPC_URL" "0x$(jq -r .signed_ethereum_transaction "$TEMP/set_root_out.json")"
cast call "$CONTRACT" 'activeRoot()(bytes32)' --rpc-url "$RPC_URL" \
  |grep -q "$ROOT" || { echo "FAIL: active root not set"; exit 1; }
echo "PASS: setActiveRoot"


# Test containsLeafHash?
LEAF0=0x0693e6761b37d88d77eb11e42e2fed1452bc5aa8a1566f5d5e4ec3c123e5aa04
LEAF1=0x015bf386477e7948a51fd27848739f156fb2bb3907e62c326d90f5f71d07e858
WRONG=0x0693e6761b37d88d77eb11e42e2fed1452bc5aa8a1566f5d5e4ec3c123e5aa88


# Test transferOwnership
NONCE=$(cast nonce "$ADDR" --rpc-url "$RPC_URL")
sed "s/chain '222'/chain '$CHAIN_ID'/" transfer_ownership.zen > "$TEMP/transfer_ownership.zen"
cat << EOF > "$TEMP/transfer_ownership.json"
{
    "gas price": "$GAS",
    "gas limit": "300000",
    "ethereum nonce": "$NONCE",
    "contract_address": "$CONTRACT",
    "newOwner_address": "$UPDATER_ADDR" 
}
EOF
"$ZENROOM" -z -a "$TEMP/transfer_ownership.json" -k "$TEMP/myKeyring.json" -l swiss_merkle.lua "$TEMP/transfer_ownership.zen" > "$TEMP/transfer_ownership_out.json"
cast publish --rpc-url "$RPC_URL" "0x$(jq -r .signed_ethereum_transaction "$TEMP/transfer_ownership_out.json")"
cast call "$CONTRACT" 'owner()(address)' --rpc-url "$RPC_URL" \
  |grep -q "$UPDATER_ADDR" || { echo "FAIL: ownership not transferred"; exit 1; }
echo "PASS: transferOwnership"



