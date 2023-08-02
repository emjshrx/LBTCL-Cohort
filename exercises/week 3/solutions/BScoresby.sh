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
    /usr/local/bin/bitcoin/bin/bitcoin-cli -datadir=/home/$USER/.bitcoin/tmp -named createwallet wallet_name="$1"
}

create_address(){
    /usr/local/bin/bitcoin/bin/bitcoin-cli -datadir=/home/$USER/.bitcoin/tmp -rpcwallet=$1 getnewaddress
}

mine_new_blocks(){
    MINER1=`create_address $1`
    /usr/local/bin/bitcoin/bin/bitcoin-cli -datadir=/home/$USER/.bitcoin/tmp generatetoaddress $2 "$MINER1" > /dev/null
}

send_coins(){
    /usr/local/bin/bitcoin/bin/bitcoin-cli -datadir=/home/$USER/.bitcoin/tmp -rpcwallet=$1 sendtoaddress $2 $3
}

get_address_pubkey(){
    /usr/local/bin/bitcoin/bin/bitcoin-cli -datadir=/home/$USER/.bitcoin/tmp -named -rpcwallet=$1 getaddressinfo address=$2 | jq -r '.pubkey'
}

create_multi(){
    MINER_ADDR=$(create_address Miner)
    MINER_PUBKEY=$(get_address_pubkey Miner $MINER_ADDR)
    echo $MINER_PUBKEY
    
    ALICE_ADDR=$(create_address Alice)
    ALICE_PUBKEY=$(get_address_pubkey Alice $ALICE_ADDR)
    
    BOB_ADDR=$(create_address Bob)
    BOB_PUBKEY=$(get_address_pubkey Bob $BOB_ADDR)
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

#1. Create three wallets: Miner, Alice and Bob
create_wallet Miner
create_wallet Alice
create_wallet Bob

#2. Fund the wallets by generating some blocks and sending coins to Alice and Bob
mine_new_blocks Miner 103
ALICE1=$(create_address Alice)
BOB1=$(create_address Bob)
TXIDA=$(send_coins Miner $ALICE1 30)
TXIDB=$(send_coins Miner $BOB1 30)
create_multi


#Cleanup
cleanup

