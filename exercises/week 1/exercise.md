# Problem Statement

Write a shell script to:

 - Download Bitcoin core binaries from Bitcoin Core Org https://bitcoincore.org/ .
 - Use the downloaded hashes and signature to verify that binary is right. Print a message "Binary signature verification succesful".
 - Copy the downloaded binaries to `/usr/local/bin/` for folder.

 - Create a `bitcoin.conf` file in the `/home/<user-name>/.bitcoin/` data directory. Create the directory if it doesn't exist. And add the following lines to the file.
  ```
    regtest=1
    fallbackfee=0.0001
    server=1
    txindex=1
  ```
  - start `bitcoind`.
  - create two wallet `Miner` and `Trader`.
  - Generate one address from the `Miner` wallet with a label "Mining Reward" and generate 101 blocks to it's address.
  - Print the Balance of `Miner` Wallet. (Bonus: Write a short comment why the balance is not equal to 101* 50 BTC).
  - Create a receiving addressed labeled "Received Coins" from `Trader` wallet.
  - Send a transaction paying 20 BTC from `Miner` wallet to `Trader`'s wallet.
  - Fetch the unconfirmed transaction from the node's mempool and print the result. (hint: `bitcoin-cli help` to find list of all commands, look for `getmempoolentry`).
  - Confirm the transaction by creating 1 more block.
  - Fetch the following details of the transaction and print them into terminal.
    - txid: <transaction id>
    - <From, Amount>: <Miner's address>, Input Amount.
    - <Send, Amount>: <Trader's address>, Sent Amount,
    - <Change, Amount>: <Miner's address>, Change Back amount.
    - Fees: Amount paid in fees.
    - Block: Block height at which the transaction is confirmed.


# Hints

- To download the latest binaries for linux x86-64, via command line: `wget https://bitcoincore.org/bin/bitcoin-core-25.0/bitcoin-25.0-x86_64-linux-gnu.tar.gz`
- Search up in google for command line instructions on tasks you don't know yet. Ex: "how to extract a zip folder via command line", "how to copy files into another directory via command line", etc.

# Reading Materials