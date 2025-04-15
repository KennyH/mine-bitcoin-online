#!/bin/bash

# This script installs Bitcoin Core and starts it syncing.
# Syncing the mainnet blockchain can take a few days to complete.

# Variables
BITCOIN_VERSION="28.1" # you can see live versions here: https://bitcoin.clarkmoody.com/dashboard/
RPC_USER=$(hostname)
RPC_PASSWORD=$(openssl rand -hex 32)
BITCOIN_DIR="$HOME/.bitcoin"

# Prerequisites
sudo apt update
sudo apt install git build-essential libtool autotools-dev automake pkg-config libevent-dev bsdmainutils python3 libboost-all-dev libssl-dev libminiupnpc-dev libzmq3-dev -y

# Download Bitcoin Core
cd ~
wget https://bitcoincore.org/bin/bitcoin-core-${BITCOIN_VERSION}/bitcoin-${BITCOIN_VERSION}-aarch64-linux-gnu.tar.gz
wget https://bitcoincore.org/bin/bitcoin-core-${BITCOIN_VERSION}/SHA256SUMS
wget https://bitcoincore.org/bin/bitcoin-core-${BITCOIN_VERSION}/SHA256SUMS.asc

# Verify
sha256sum --ignore-missing -c SHA256SUMS
if [ $? -ne 0 ]; then
  echo "Bitcoin Core binary verification failed. Exiting."
  exit 1
fi

# Install Bitcoin Core

 tar -xvf bitcoin-${BITCOIN_VERSION}-aarch64-linux-gnu.tar.gz
 sudo install -m 0755 -o root -g root -t /usr/local/bin bitcoin-${BITCOIN_VERSION}/bin/*

# Configure
mkdir -p ${BITCOIN_DIR}
cat << EOF > ${BITCOIN_DIR}/bitcoin.conf
# Bitcoin Core basic configuration
daemon=1
server=1
txindex=1
rpcuser=${RPC_USER}
rpcpassword=${RPC_PASSWORD}
rpcallowip=127.0.0.1
prune=0
dbcache=2048
maxconnections=40
EOF

# Setup systemd service
sudo bash -c 'cat << EOF > /etc/systemd/system/bitcoind.service
[Unit]
Description=Bitcoin daemon
After=network.target

[Service]
ExecStart=/usr/local/bin/bitcoind -daemon -conf=/home/pi/.bitcoin/bitcoin.conf -datadir=/home/pi/.bitcoin
ExecStop=/usr/local/bin/bitcoin-cli stop
User=pi
Group=pi
Type=forking
Restart=always
TimeoutSec=120
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF'

# Enable & start service
sudo systemctl enable bitcoind
sudo systemctl start bitcoind

# Wait for bitcoind to initialize
sleep 10

# Check initial status
/usr/local/bin/bitcoin-cli getblockchaininfo

echo "=========================================================="
echo "[x] Bitcoin Core Node installation is complete!"
echo "[x] RPC Username: ${RPC_USER}"
echo "[x] RPC Password: ${RPC_PASSWORD}"
echo "[!] IMPORTANT: Securely store your RPC password."
echo "[!] BACKUP your wallet and important node data regularly."
echo "=========================================================="
