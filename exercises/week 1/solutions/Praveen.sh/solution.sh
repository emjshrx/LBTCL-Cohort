#!/bin/bash

echo "Let there be a node"

# Download core binary for mac

wget https://bitcoincore.org/bin/bitcoin-core-25.0/bitcoin-25.0-arm64-apple-darwin.dmg

# Download the hash and signature files and verify that the hash matches the hash of the file you downloaded.

wget https://bitcoincore.org/bin/bitcoin-core-25.0/SHA256SUMS.asc
wget https://bitcoincore.org/bin/bitcoin-core-25.0/SHA256SUMS



# Verify the hash of the binary file.

shasum --check SHA256SUMS | grep OK > /dev/null 2>&1

#If successful verification then printmessage to terminal that Binary hash verification successful"

if [ $? -eq 0 ]; then
    echo "Binary hash verification successful"
else
    echo "Binary hash verification failed"
fi

# Verify the signature of the hash file.

gpg --verify SHA256SUMS.asc SHA256SUMS > /dev/null 2>&1

# write a if condition to check if the signature is verified or not

if [ $? -eq 0 ]; then
    echo "Signature verification successful"
else
    echo "Signature verification failed"
fi

