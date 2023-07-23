#!/bin/bash

echo "Let there be a node"

# Download core binary for mac

wget https://bitcoincore.org/bin/bitcoin-core-25.0/bitcoin-25.0-arm64-apple-darwin.dmg

# Download the hash and signature files and verify that the hash matches the hash of the file you downloaded.

wget https://bitcoincore.org/bin/bitcoin-core-25.0/SHA256SUMS.asc
wget https://bitcoincore.org/bin/bitcoin-core-25.0/SHA256SUMS



# Verify the hash of the binary file.

shasum --check SHA256SUMS 2>/dev/null | grep OK

#If successful verification then printmessage to terminal that Binary hash verification successful"

if [ $? -eq 0 ]; then
    echo "Binary hash verification successful"
else
    echo "Binary hash verification failed"
fi

# Verify the signature of the hash file.

gpg --verify SHA256SUMS.asc SHA256SUMS 2>/dev/null

# write a if condition to check if the signature is verified or not

if [ $? -eq 0 ]; then
    echo "Signature verification successful"
else
    echo "Signature verification failed"
fi

# check if bitcoin core is installed via homebrew casks,if not install it

brew ls | grep "bitcoin-core"

if [ $? -eq 0 ]; then
    echo "Bitcoin core is installed"
else
    echo "Bitcoin core is not installed"
    brew install bitcoin-core
fi



# Create a bitcoin.conf file in the /Users/$USER/Library/Application Support/Bitcoin

mkdir -p /Users/$USER/Library/Application\ Support/Bitcoin
echo "regtest=1" >> /Users/$USER/Library/Application\ Support/Bitcoin/bitcoin.conf
echo "fallbackfee=0.0001" >> /Users/$USER/Library/Application\ Support/Bitcoin/bitcoin.conf
echo "server=1" >> /Users/$USER/Library/Application\ Support/Bitcoin/bitcoin.conf

# Start bitcoind in the background
bitcoind -daemon

### wait for 10 seconds

sleep 10

# Now you can run bitcoin-cli getinfo
bitcoin-cli -getinfo





