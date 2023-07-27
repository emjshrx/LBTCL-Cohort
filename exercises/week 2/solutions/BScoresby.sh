#!/bin/bash

#Global variables
DIR=/usr/local/bin/bitcoin/bin

install_jq(){
    if ! command -v jq &> /dev/null
    then
        sudo apt-get install jq
    fi
}

start_bitcoind(){
    $DIR/bitcoind -daemon
    sleep 5
}

reset_regtest(){
    if [ -d /home/$USER/.bitcoin/regtest ];
    then
        while true; do
            read -p "Program needs to reset Regtest. All Regtest data will be erased. Proceed? (Y/N) " eraseregtest
            case $eraseregtest in
                [yY]*) echo "Deleting regtest folder...";
                    rm -r /home/$USER/.bitcoin/regtest;
                    break;;
                [nN]*) echo "Exiting...";
                    exit 1;;
                *) echo "Invalid reponse, please use Y or N" >&2
            esac
        done
    fi
}

create_miner_wallet(){
    $DIR/bitcoin-cli -named createwallet wallet_name="Miner"
}

create_miner_address(){
    $DIR/bitcoin-cli -rpcwallet=Miner getnewaddress "$1"
}

mine_new_blocks(){
    MINER1=`create_miner_address $1`
    $DIR/bitcoin-cli generatetoaddress $2 "$MINER1" > /dev/null
}

create_trader_wallet(){
    $DIR/bitcoin-cli -named createwallet wallet_name="Trader"
}

create_trader_address(){
    $DIR/bitcoin-cli -rpcwallet=Trader getnewaddress $1
}

create_parent_transaction(){
    MINERTXID=($($DIR/bitcoin-cli -rpcwallet=Miner listunspent | jq -r '.[] | .txid'))
    MINERVOUT=($($DIR/bitcoin-cli -rpcwallet=Miner listunspent | jq -r '.[] | .vout'))
    
    UTXO1_TXID=${MINERTXID[0]}
    UTXO1_VOUT=${MINERVOUT[0]}
    UTXO2_TXID=${MINERTXID[1]}
    UTXO2_VOUT=${MINERVOUT[0]}
    TRADER_ADDR=`create_trader_address Trader1`
    CHANGE_ADDR=`create_miner_address Miner2`

    PARENT=$($DIR/bitcoin-cli -rpcwallet=Miner -named createrawtransaction inputs='''[{"txid": "'$UTXO1_TXID'", "vout": '$UTXO1_VOUT', "sequence": 1 }, {"txid": "'$UTXO2_TXID'", "vout": '$UTXO2_VOUT', "sequence": 1 }]''' outputs='''{"'$TRADER_ADDR'": 70.0, "'$CHANGE_ADDR'": 29.999 }''')   

#    PARENT_TXID=$($DIR/bitcoin-cli decoderawtransaction $PARENT | jq -r '.txid')
}

sign_transaction(){
    unset signedtx
    signedtx=$($DIR/bitcoin-cli -rpcwallet=$1 -named signrawtransactionwithwallet hexstring=$2 | jq -r '.hex')
    echo "transaction signed"
}

send_transaction(){
    $DIR/bitcoin-cli -rpcwallet=$1 -named sendrawtransaction hexstring=$signedtx
    echo "transaction sent"
}

get_mempool_entry(){

    PARENT_TXID=$($DIR/bitcoin-cli -rpcwallet=Trader listtransactions | jq -r '.[0] | .txid')
    FEES=$($DIR/bitcoin-cli -rpcwallet=Trader getmempoolentry $PARENT_TXID | jq -r '.fees.base')
    WEIGHT=$($DIR/bitcoin-cli -rpcwallet=Trader getmempoolentry $PARENT_TXID | jq -r '.weight')
    HEX=$($DIR/bitcoin-cli -rpcwallet=Trader gettransaction $PARENT_TXID | jq -r '.hex')
    PARENT_INPUT_TXID=($($DIR/bitcoin-cli decoderawtransaction $HEX | jq -r '.vin | .[] | .txid'))
    PARENT_INPUT_VOUT=($($DIR/bitcoin-cli decoderawtransaction $HEX | jq -r '.vin | .[] | .vout'))
    PARENT_OUTPUT_AMOUNT=($($DIR/bitcoin-cli decoderawtransaction $HEX | jq -r '.vout | .[] | .value'))
    PARENT_OUTPUT_SPUBKEY=($($DIR/bitcoin-cli decoderawtransaction $HEX | jq -r '.vout | .[] | .scriptPubKey.hex'))

    echo "Parent txid: $PARENT_TXID"
    echo "Parent input txid 1: ${PARENT_INPUT_TXID[0]}" 
    echo "Parent input txid 2: ${PARENT_INPUT_TXID[1]}"
    echo "Parent input vout 1: ${PARENT_INPUT_VOUT[0]}" 
    echo "Parent input vout 2: ${PARENT_INPUT_VOUT[1]}"
    echo "Parent output 1 amount: ${PARENT_OUTPUT_AMOUNT[0]} BTC"
    echo "Parent output 2 amount: ${PARENT_OUTPUT_AMOUNT[1]} BTC"
    echo "Trader scriptPubKey: ${PARENT_OUTPUT_SPUBKEY[0]}"
    echo "Miner change scriptPubKey: ${PARENT_OUTPUT_SPUBKEY[1]}"      
    echo "Parent transaction fees: $FEES BTC"
    echo "Parent transaction weight: $((WEIGHT/4)) vbytes"
}

create_child_transaction(){
    PARENT_OUTPUT_VOUT=($($DIR/bitcoin-cli decoderawtransaction $HEX | jq -r '.vout | .[] | .n'))
    MINER_ADDR_2=`create_miner_address Miner3`

#    echo "Parent txid: $PARENT_TXID"
#    echo "Parent output vout: ${PARENT_OUTPUT_VOUT[1]}"
#    echo "New miner address: $MINER_ADDR_2"

    CHILD=$($DIR/bitcoin-cli -rpcwallet=Miner -named createrawtransaction inputs='''[{"txid": "'$PARENT_TXID'", "vout": '${PARENT_OUTPUT_VOUT[1]}', "sequence": 1 }]''' outputs='''{"'$MINER_ADDR_2'": 29.9 }''')   

}

stop_bitcoind(){
    $DIR/bitcoin-cli stop
}



#Setup
reset_regtest
sleep 1
start_bitcoind
install_jq

#1. Create two wallets named Miner and Trader
create_miner_wallet
create_trader_wallet
create_miner_address Miner1

#2. Fund the Miner wallet with at least 3 block rewards worth of sats
mine_new_blocks Miner1 103

#3. Craft a transaction from Miner to Trader called Parent transaction
create_parent_transaction

#4. Sign and broadcast the transaction
sign_transaction Miner "$PARENT"
send_transaction

#5. Make queries to the node's mempool to get Parent transaction details
get_mempool_entry
#echo $HEX
create_child_transaction
sign_transaction Miner "$CHILD"
send_transaction
#Cleanup
#stop_bitcoind




# CODE FOR GRABBING ADDRESS BY LABEL
#    MINER1=`$DIR/bitcoin-cli -rpcwallet=Miner getaddressesbylabel "$1" | jq -r 'keys[0]'`

