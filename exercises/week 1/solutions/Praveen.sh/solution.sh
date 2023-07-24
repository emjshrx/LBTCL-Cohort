#!/bin/bash

echo "Let there be a node"


# Function to download the binary, hash and signature files
download_binary() {
    echo "Downloading the binary, hash and signature files"
    wget https://bitcoincore.org/bin/bitcoin-core-25.0/bitcoin-25.0-arm64-apple-darwin.dmg
    wget https://bitcoincore.org/bin/bitcoin-core-25.0/SHA256SUMS.asc
    wget https://bitcoincore.org/bin/bitcoin-core-25.0/SHA256SUMS
}

# Function to verify the hash of the binary file
verify_binary_hash() {
    echo "Verifying the hash of the binary file"
    shasum --check SHA256SUMS 2>/dev/null | grep OK

    # If successful verification then print message to terminal that Binary hash verification successful"
    if [ $? -eq 0 ]; then
        echo "Binary hash verification successful"
    else
        echo "Binary hash verification failed"
    fi
}

# Function to verify the signature of the hash file
verify_signature() {
    echo "Verifying the signature of the hash file"
    gpg --verify SHA256SUMS.asc SHA256SUMS 2>/dev/null

    # Write an if condition to check if the signature is verified or not
    if [ $? -eq 0 ]; then
        echo "Signature verification successful"
    else
        echo "Signature verification failed"
    fi
}

# Function to check if bitcoin core is installed via homebrew casks, if not install it
check_installation() {
    echo "Checking if bitcoin core is installed on your mac"
    brew ls | grep "bitcoin-core"

    if [ $? -eq 0 ]; then
        echo "Bitcoin core is installed"
    else
        echo "Bitcoin core is not installed"
        brew install bitcoin-core
    fi
}

# Function to create a bitcoin.conf file in the /Users/$USER/Library/Application Support/Bitcoin
create_conf_file() {
    echo "Creating bitcoin.conf file"
    cd /Users/$USER/Library/Application\ Support/Bitcoin

    # Create a file called bitcoin.conf
    touch bitcoin.conf

    echo "regtest=1" >> bitcoin.conf
    echo "fallbackfee=0.0001" >> bitcoin.conf
    echo "server=1" >> bitcoin.conf
    echo "txindex=1" >> bitcoin.conf
}

# Function to delete regtest dir if already exists within /Users/$USER/Library/Application\ Support/Bitcoin
delete_regtest_dir() {
    echo "Deleting regtest directory if exists"
    if [ -d "/Users/$USER/Library/Application\ Support/Bitcoin/regtest" ]; then
        rm -rf /Users/$USER/Library/Application\ Support/Bitcoin/regtest
    fi
}



# Function to start bitcoind in the background and run the last command
start_bitcoind() {
    echo "Starting bitcoind"
    # Start bitcoind in the background
    bitcoind -daemon

    # Wait for 10 seconds
    sleep 10

    # Now you can run bitcoin-cli getinfo
    bitcoin-cli -getinfo
}

# Function to create 2 wallets called Miner and Trader

create_wallets() {
    echo "Creating two wallets"
    # Create a wallet called Miner
    bitcoin-cli createwallet "Miner"

    # Create a wallet called Trader
    bitcoin-cli createwallet "Trader"
}

# Function to Generate one address from the Miner wallet with a label "Mining Reward".
# Mine new blocks to this address until you get positive wallet balance. (use generatetoaddress) (how many blocks it took to get to positive balance)

generate_address_and_mine_blocks() {
    #  In regtest mode, the block generation time is significantly reduced to allow for faster testing
    #  and development. By generating 101 blocks, a sufficient number of confirmations is achieved, and
    #  the network considers the transactions confirmed and reflects the updated wallet balance.
    echo "Generate an address for miner and mine blocks"
    miner_address=$(bitcoin-cli -rpcwallet="Miner" getnewaddress "Mining Reward")
    bitcoin-cli -rpcwallet="Miner" generatetoaddress 101 $miner_address
    bitcoin-cli -rpcwallet="Miner" getbalance
}

# Function to Create a receiving addressed labeled "Received" from Trader wallet.
# Send a transaction paying 20 BTC from Miner wallet to Trader's wallet.
# print the transaction id and check the mempool for the transaction

generate_trader_address() {
    echo "Generate an address for trader"
    amount=20
    trader_address=$(bitcoin-cli -rpcwallet="Trader" getnewaddress "Received")
    tx_id=$(bitcoin-cli -rpcwallet="Miner" sendtoaddress $trader_address $amount)
    echo "Transaction ID: $tx_id"
    bitcoin-cli getmempoolentry $tx_id
}

# Function to Confirm the transaction by creating 1 more block.

confirm_block() {
    echo "Generating one additional block"
    bitcoin-cli -rpcwallet="Miner" -generate 1
    bitcoin-cli -rpcwallet="Miner" getbalance
}

# Function to display transaction details

display_transaction_details() {
    echo "Display transaction details"
    bitcoin-cli -rpcwallet="Miner"  gettransaction "${tx_id}" true
    fee=$(bitcoin-cli -rpcwallet="Miner" gettransaction $tx_id | jq '.fee')
    blockheight=blockheight=$(bitcoin-cli -rpcwallet="Miner" gettransaction $tx_id | jq '.blockheight')
    echo "Transaction ID: $tx_id"
    echo "<From, Amount>: ${miner_address}, ${amount}"
	echo "<Send, Amount>: ${trader_address}, ${amount}"
    echo "Fee: $fee"
    echo "Block Height: $blockheight"
    echo "Miner Balance: $( bitcoin-cli -rpcwallet="Miner" getbalance )"
	echo "Trader Balance: $( bitcoin-cli -rpcwallet="Trader" getbalance )"

}






# Call the functions in the desired order
download_binary
verify_binary_hash
verify_signature
check_installation
delete_regtest_dir
create_conf_file
start_bitcoind
create_wallets
generate_address_and_mine_blocks
generate_trader_address
confirm_block
display_transaction_details



