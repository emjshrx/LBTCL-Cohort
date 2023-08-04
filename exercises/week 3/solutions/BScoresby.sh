#!/bin/bash

setup(){
    mkdir -p /home/$USER/.bitcoin/tmp;
    touch /home/$USER/.bitcoin/tmp/bitcoin.conf
    echo "regtest=1  
	fallbackfee=0.0001
        server=1
        txindex=1
        daemon=1" >> /home/$USER/.bitcoin/tmp/bitcoin.conf
}

install_jq(){
    if ! command -v jq &> /dev/null
    then
        sudo apt-get install jq
    fi
}

start_bitcoind(){
    /usr/local/bin/bitcoin/bin/bitcoind -datadir=/home/$USER/.bitcoin/tmp -daemon
    sleep 3
}

create_wallet(){
    /usr/local/bin/bitcoin/bin/bitcoin-cli -datadir=/home/$USER/.bitcoin/tmp -named createwallet wallet_name="$1" disable_private_keys="$2" blank="$3" 1> /dev/null
}

create_address(){
    /usr/local/bin/bitcoin/bin/bitcoin-cli -datadir=/home/$USER/.bitcoin/tmp -rpcwallet=$1 getnewaddress
}

mine_new_blocks(){
    MINER1=`create_address $1`
    /usr/local/bin/bitcoin/bin/bitcoin-cli -datadir=/home/$USER/.bitcoin/tmp generatetoaddress $2 "$MINER1" > /dev/null
}

send_coins(){
    /usr/local/bin/bitcoin/bin/bitcoin-cli -datadir=/home/$USER/.bitcoin/tmp -rpcwallet=$1 -named sendtoaddress address="$2" amount="$3" fee_rate=25 
}

get_address_pubkey(){
    /usr/local/bin/bitcoin/bin/bitcoin-cli -datadir=/home/$USER/.bitcoin/tmp -named -rpcwallet=$1 getaddressinfo address=$2 | jq -r '.pubkey'
}

get_balance(){
    /usr/local/bin/bitcoin/bin/bitcoin-cli -datadir=/home/$USER/.bitcoin/tmp -named -rpcwallet=$1 getbalance
}

list_unspent(){
    /usr/local/bin/bitcoin/bin/bitcoin-cli -datadir=/home/$USER/.bitcoin/tmp -named -rpcwallet=$1 listunspent
}

create_multi(){
    FIRST_ADDR=$(create_address $1)
    FIRST_PUBKEY=$(get_address_pubkey $1 $FIRST_ADDR)
    
    SECOND_ADDR=$(create_address $2)
    SECOND_PUBKEY=$(get_address_pubkey $2 $SECOND_ADDR)

    MULTI=$(/usr/local/bin/bitcoin/bin/bitcoin-cli -datadir=/home/$USER/.bitcoin/tmp -rpcwallet=$1 -named createmultisig nrequired=2 keys='''["'$FIRST_PUBKEY'", "'$SECOND_PUBKEY'"]''')
    
    MULTI2=$(/usr/local/bin/bitcoin/bin/bitcoin-cli -datadir=/home/$USER/.bitcoin/tmp -rpcwallet=$2 -named createmultisig nrequired=2 keys='''["'$FIRST_PUBKEY'", "'$SECOND_PUBKEY'"]''')

#The following doesn't work because it is only supported by legacy wallets and throws errors
#    MULTI=$(/usr/local/bin/bitcoin/bin/bitcoin-cli -datadir=/home/$USER/.bitcoin/tmp -rpcwallet=$1 -named addmultisigaddress nrequired=2 keys='''["'$FIRST_ADDR'", "'$SECOND_PUBKEY'"]''')
    
#    MULTI2=$(/usr/local/bin/bitcoin/bin/bitcoin-cli -datadir=/home/$USER/.bitcoin/tmp -rpcwallet=$2 -named addmultisigaddress nrequired=2 keys='''["'$FIRST_PUBKEY'", "'$SECOND_ADDR'"]''')

    MULTI_ADDR=$(echo "$MULTI" | jq -r '.address')
    MULTI_REDEEM=$(echo "$MULTI" | jq -r '.redeemScript')
    MULTI_DESCRIPTOR=$(echo "$MULTI" | jq -r '.descriptor')
#    echo "Multisig address: $MULTI_DESCRIPTOR"    
}

funding_psbt(){
    TXID1=$(/usr/local/bin/bitcoin/bin/bitcoin-cli -datadir=/home/$USER/.bitcoin/tmp -named -rpcwallet=$1 listunspent | jq -r '.[0] | .txid')
    VOUT1=$(/usr/local/bin/bitcoin/bin/bitcoin-cli -datadir=/home/$USER/.bitcoin/tmp -named -rpcwallet=$1 listunspent | jq -r '.[0] | .vout')
    TXID2=$(/usr/local/bin/bitcoin/bin/bitcoin-cli -datadir=/home/$USER/.bitcoin/tmp -named -rpcwallet=$2 listunspent | jq -r '.[0] | .txid')
    VOUT2=$(/usr/local/bin/bitcoin/bin/bitcoin-cli -datadir=/home/$USER/.bitcoin/tmp -named -rpcwallet=$2 listunspent | jq -r '.[0] | .vout')
    ALICE_CHANGE=$(/usr/local/bin/bitcoin/bin/bitcoin-cli -datadir=/home/$USER/.bitcoin/tmp -rpcwallet=Alice getrawchangeaddress)
    BOB_CHANGE=$(/usr/local/bin/bitcoin/bin/bitcoin-cli -datadir=/home/$USER/.bitcoin/tmp -rpcwallet=Bob getrawchangeaddress)
#    MULTI_ADDR=$(create_address Multi)

    PSBT1=$(/usr/local/bin/bitcoin/bin/bitcoin-cli -datadir=/home/$USER/.bitcoin/tmp -named createpsbt inputs='''[ { "txid": "'$TXID1'", "vout": '$VOUT1' }, { "txid": "'$TXID2'", "vout": '$VOUT2' } ]''' outputs='''[ { "'$MULTI_ADDR'": 20 }, { "'$ALICE_CHANGE'": 19.9998 }, { "'$BOB_CHANGE'": 19.9998 } ]''' ) 

#updating psbt
    PSBT1A=$(/usr/local/bin/bitcoin/bin/bitcoin-cli -datadir=/home/$USER/.bitcoin/tmp -rpcwallet=Alice walletprocesspsbt "$PSBT1" | jq -r '.psbt')

    PSBT1AB=$(/usr/local/bin/bitcoin/bin/bitcoin-cli -datadir=/home/$USER/.bitcoin/tmp -rpcwallet=Bob walletprocesspsbt "$PSBT1A" | jq -r '.psbt')

#finalizing psbt    
    HEX=$(/usr/local/bin/bitcoin/bin/bitcoin-cli -datadir=/home/$USER/.bitcoin/tmp -rpcwallet=Bob finalizepsbt "$PSBT1AB" | jq -r '.hex')

#broadcasting psbt
    /usr/local/bin/bitcoin/bin/bitcoin-cli -datadir=/home/$USER/.bitcoin/tmp -rpcwallet=Bob -named sendrawtransaction hexstring=$HEX
}

import_descriptor(){
    /usr/local/bin/bitcoin/bin/bitcoin-cli -datadir=/home/$USER/.bitcoin/tmp -rpcwallet=$1 importdescriptors '''[ { "desc": "'$MULTI_DESCRIPTOR'", "timestamp": "now"} ]'''
}

spending_psbt(){
    ALICE_ADDR=$(create_address Alice)
    echo "Alice's address $ALICE_ADDR"
    BOB_ADDR=$(create_address Bob)
    echo "Bob's address: $BOB_ADDR"
#    MULTI_CHANGE_ADDR=$(create_address Multi)
    MULTI_CHANGE_ADDR=$(/usr/local/bin/bitcoin/bin/bitcoin-cli -datadir=/home/$USER/.bitcoin/tmp -rpcwallet=$1 deriveaddresses "$MULTI_DESCRIPTOR" | jq -r '.[0]')
    echo "Multisig change address: $MULTI_CHANGE_ADDR"
    MULTI_TXID_1=$(/usr/local/bin/bitcoin/bin/bitcoin-cli -datadir=/home/$USER/.bitcoin/tmp -rpcwallet=$1 listunspent | jq -r '.[0] | .txid')
    echo "spending psbt txid $MULTI_TXID_1"
#    /usr/local/bin/bitcoin/bin/bitcoin-cli -datadir=/home/$USER/.bitcoin/tmp -rpcwallet=$1 listunspent
#    WTXID=$(/usr/local/bin/bitcoin/bin/bitcoin-cli -datadir=/home/$USER/.bitcoin/tmp -rpcwallet=$1 gettransaction "$MULTI_TXID_1" | jq -r '.wtxid')
    echo "Wxtid: $WTXID"    
    
    MULTI_VOUT_1=$(/usr/local/bin/bitcoin/bin/bitcoin-cli -datadir=/home/$USER/.bitcoin/tmp -rpcwallet=$1 listunspent | jq '.[0] | .vout')

    PSBT2=$(/usr/local/bin/bitcoin/bin/bitcoin-cli -datadir=/home/$USER/.bitcoin/tmp -named createpsbt inputs='''[ { "txid": "'$MULTI_TXID_1'", "vout": '$MULTI_VOUT_1' } ]''' outputs='''[ { "'$ALICE_ADDR'": 5 }, { "'$BOB_ADDR'": 5 }, { "'$MULTI_CHANGE_ADDR'" : 9.998 } ]''' ) 
#    echo "$PSBT2"    
    
#updating psbt
    PSBT2A=$(/usr/local/bin/bitcoin/bin/bitcoin-cli -datadir=/home/$USER/.bitcoin/tmp -rpcwallet=Alice walletprocesspsbt "$PSBT2" | jq -r '.psbt')

    PSBT2AB=$(/usr/local/bin/bitcoin/bin/bitcoin-cli -datadir=/home/$USER/.bitcoin/tmp -rpcwallet=Bob walletprocesspsbt "$PSBT2A" | jq -r '.psbt')

#combining psbt
#    PSBT2C=$(/usr/local/bin/bitcoin/bin/bitcoin-cli -datadir=/home/$USER/.bitcoin/tmp -rpcwallet=Alice combinepsbt '''["'$PSBT2A'", "'$PSBT2B'"]''')
#    echo "$PSBT2C"
    
#finalizing psbt    
    /usr/local/bin/bitcoin/bin/bitcoin-cli -datadir=/home/$USER/.bitcoin/tmp -rpcwallet=Alice finalizepsbt "$PSBT2AB"
#    /usr/local/bin/bitcoin/bin/bitcoin-cli -datadir=/home/$USER/.bitcoin/tmp decodepsbt "$PSBT2AB"
    
#    HEX=$(/usr/local/bin/bitcoin/bin/bitcoin-cli -datadir=/home/$USER/.bitcoin/tmp -rpcwallet=Alice finalizepsbt "$PSBT2C" | jq -r '.hex')

#broadcasting psbt
#    /usr/local/bin/bitcoin/bin/bitcoin-cli -datadir=/home/$USER/.bitcoin/tmp -rpcwallet=Bob -named sendrawtransaction hexstring=$HEX
}

cleanup(){
    /usr/local/bin/bitcoin/bin/bitcoin-cli -datadir=/home/$USER/.bitcoin/tmp stop
    sleep 2
    rm -rf /home/$USER/.bitcoin/tmp
}





#Setup
setup
install_jq
start_bitcoind

#SETUP MULTISIG
#1. Create three wallets: Miner, Alice and Bob
create_wallet Miner false false
create_wallet Alice false false
create_wallet Bob false false

#2. Fund the wallets by generating some blocks and sending coins to Alice and Bob
mine_new_blocks Miner 103
ALICE1=$(create_address Alice)
BOB1=$(create_address Bob)
TXIDA=$(send_coins Miner $ALICE1 30)
TXIDB=$(send_coins Miner $BOB1 30)
mine_new_blocks Miner 1
get_balance Alice
get_balance Bob

#3. Create 2 of 2 Multisig for Alice and Bob
create_multi Alice Bob
create_wallet Multi true true
import_descriptor Multi
#FUND_MULTI_ADDR=$(echo "$MULTI" | jq -r '.address')
#FUND_MULTI_REDEEM=$(echo "$MULTI" | jq -r '.redeemScript')
#FUND_MULTI_DESCRIPTOR=$(echo "$MULTI" | jq -r '.descriptor')
#echo "$FUND_MULTI_ADDR"

#4. Create PSBT funding multisig with 20BTC
funding_psbt Alice Bob

#5. Confirm balance by mining a few more blocks
mine_new_blocks Miner 3

#6. Print final balances of Alice and Bob
echo "Alice balance: $(get_balance Alice)"
echo "Bob balance: $(get_balance Bob)"

#SETTLE MULTISIG
#1. Create PSBT to spend from multisig
spending_psbt Multi
#mine_new_blocks Miner 3

#echo "Alice balance: $(get_balance Alice)"
#echo "Bob balance: $(get_balance Bob)"
#/usr/local/bin/bitcoin/bin/bitcoin-cli -datadir=/home/$USER/.bitcoin/tmp -rpcwallet=Bob -named decoderawtransaction hexstring=$HEX
#Cleanup
cleanup

