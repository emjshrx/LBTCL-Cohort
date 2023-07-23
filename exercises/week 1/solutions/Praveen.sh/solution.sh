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

# install the above binary and move the binaries to /usr/local/bin/ for folder.

sudo hdiutil attach bitcoin-25.0-arm64-apple-darwin.dmg
sudo cp -r /Volumes/Bitcoin-Core/bitcoin-25.0/* /usr/local/bin/
sudo chown -R $USER /usr/local/bin/bitcoin*
sudo chmod 755 /usr/local/bin/bitcoin*

# Create a bitcoin.conf file in the /Users/$USER/Library/Application Support/Bitcoin and add "regtest=1" to it:

mkdir -p /Users/$USER/Library/Application\ Support/Bitcoin
echo "regtest=1" >> /Users/$USER/Library/Application\ Support/Bitcoin/bitcoin.conf
echo "fallbackfee=0.0001" >> /Users/$USER/Library/Application\ Support/Bitcoin/bitcoin.conf
echo "server=1" >> /Users/$USER/Library/Application\ Support/Bitcoin/bitcoin.conf
echo "txindex=1" >> /Users/$USER/Library/Application\ Support/Bitcoin/bitcoin.conf





