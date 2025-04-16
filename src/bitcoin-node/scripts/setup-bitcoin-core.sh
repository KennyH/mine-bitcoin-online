#!/bin/bash

set -e

show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

This script installs and configures Bitcoin Core on your system.
It is idempotent and can be run multiple times without overwriting existing configuration,
unless the --force flag is used.

Options:
  --mainnet      Install and configure a mainnet Bitcoin node (default if no flag given)
  --testnet      Install and configure a testnet Bitcoin node
  --both         Install and configure both mainnet and testnet nodes
  --force        Overwrite existing configuration and re-install binaries/services
  -h, --help     Show this help message and exit

Examples:
  $0 --mainnet
  $0 --testnet
  $0 --both
  $0 --both --force

EOF
}

# Default values
BITCOIN_VERSION="28.1"
INSTALL_MAINNET=false
INSTALL_TESTNET=false
FORCE=false

# Parse flags
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --mainnet) INSTALL_MAINNET=true ;;
        --testnet) INSTALL_TESTNET=true ;;
        --both) INSTALL_MAINNET=true; INSTALL_TESTNET=true ;;
        --force) FORCE=true ;;
        -h|--help) show_help; exit 0 ;;
        *) echo "Unknown parameter passed: $1"; show_help; exit 1 ;;
    esac
    shift
done

# Default to mainnet if no flag is given
if ! $INSTALL_MAINNET && ! $INSTALL_TESTNET; then
    INSTALL_MAINNET=true
fi

# Variables
USER_HOME=$(eval echo ~${SUDO_USER:-$USER})
BITCOIN_USER=${SUDO_USER:-$USER}
BITCOIN_MAINNET_DIR="$USER_HOME/.bitcoin-mainnet"
BITCOIN_TESTNET_DIR="$USER_HOME/.bitcoin-testnet"
BITCOIN_BIN_DIR="/usr/local/bin"
BITCOIN_TARBALL="bitcoin-${BITCOIN_VERSION}-aarch64-linux-gnu.tar.gz"
BITCOIN_URL="https://bitcoincore.org/bin/bitcoin-core-${BITCOIN_VERSION}/${BITCOIN_TARBALL}"

# Prerequisites
sudo apt update
sudo apt install -y git build-essential libtool autotools-dev automake pkg-config libevent-dev bsdmainutils python3 libboost-all-dev libssl-dev libminiupnpc-dev libzmq3-dev wget

# Download Bitcoin Core if not already downloaded or if --force
if [ ! -f "$USER_HOME/$BITCOIN_TARBALL" ] || $FORCE; then
    cd "$USER_HOME"
    wget -N "$BITCOIN_URL"
    wget -N "https://bitcoincore.org/bin/bitcoin-core-${BITCOIN_VERSION}/SHA256SUMS"
    wget -N "https://bitcoincore.org/bin/bitcoin-core-${BITCOIN_VERSION}/SHA256SUMS.asc"
    sha256sum --ignore-missing -c SHA256SUMS
    if [ $? -ne 0 ]; then
        echo "Bitcoin Core binary verification failed. Exiting."
        exit 1
    fi
    tar -xvf "$BITCOIN_TARBALL"
    sudo install -m 0755 -o root -g root -t $BITCOIN_BIN_DIR bitcoin-${BITCOIN_VERSION}/bin/*
fi

# Function to create config
create_config() {
    local DIR=$1
    local IS_TESTNET=$2
    local CONF_FILE="$DIR/bitcoin.conf"
    local RPC_USER=$(hostname)
    local RPC_PASSWORD=$(openssl rand -hex 32)
    mkdir -p "$DIR"
    if [ ! -f "$CONF_FILE" ] || $FORCE; then
        cat << EOF > "$CONF_FILE"
# Bitcoin Core basic configuration
daemon=1
server=1
txindex=1
rpcuser=${RPC_USER}
rpcpassword=${RPC_PASSWORD}
rpcallowip=127.0.0.1
prune=0
dbcache=1024
maxconnections=20
EOF
        if $IS_TESTNET; then
            echo "testnet=1" >> "$CONF_FILE"
        fi
    fi
}

# Function to create systemd service
create_service() {
    local NAME=$1
    local DIR=$2
    local CONF_FILE="$DIR/bitcoin.conf"
    local SERVICE_FILE="/etc/systemd/system/bitcoind-${NAME}.service"
    if [ ! -f "$SERVICE_FILE" ] || $FORCE; then
        sudo bash -c "cat << EOF > $SERVICE_FILE
[Unit]
Description=Bitcoin daemon (${NAME})
After=network.target

[Service]
ExecStart=$BITCOIN_BIN_DIR/bitcoind -daemon -conf=$CONF_FILE -datadir=$DIR
ExecStop=$BITCOIN_BIN_DIR/bitcoin-cli -conf=$CONF_FILE -datadir=$DIR stop
User=$BITCOIN_USER
Group=$BITCOIN_USER
Type=forking
Restart=always
TimeoutSec=120
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF"
    fi
    sudo systemctl daemon-reload
    sudo systemctl enable "bitcoind-${NAME}.service"
    sudo systemctl restart "bitcoind-${NAME}.service"
}

# Mainnet setup
if $INSTALL_MAINNET; then
    create_config "$BITCOIN_MAINNET_DIR" false
    create_service "mainnet" "$BITCOIN_MAINNET_DIR"
    sleep 10
    $BITCOIN_BIN_DIR/bitcoin-cli -conf="$BITCOIN_MAINNET_DIR/bitcoin.conf" -datadir="$BITCOIN_MAINNET_DIR" getblockchaininfo || true
    echo "Mainnet node setup complete."
fi

# Testnet setup
if $INSTALL_TESTNET; then
    create_config "$BITCOIN_TESTNET_DIR" true
    create_service "testnet" "$BITCOIN_TESTNET_DIR"
    sleep 10
    $BITCOIN_BIN_DIR/bitcoin-cli -conf="$BITCOIN_TESTNET_DIR/bitcoin.conf" -datadir="$BITCOIN_TESTNET_DIR" getblockchaininfo || true
    echo "Testnet node setup complete."
fi

echo "=========================================================="
echo "[x] Bitcoin Core Node installation is complete!"
if $INSTALL_MAINNET; then
    echo "[x] Mainnet datadir: $BITCOIN_MAINNET_DIR"
    echo "[x] Mainnet config: $BITCOIN_MAINNET_DIR/bitcoin.conf"
fi
if $INSTALL_TESTNET; then
    echo "[x] Testnet datadir: $BITCOIN_TESTNET_DIR"
    echo "[x] Testnet config: $BITCOIN_TESTNET_DIR/bitcoin.conf"
fi
echo "[!] IMPORTANT: Securely store your RPC password(s)."
echo "[!] BACKUP your wallet and important node data regularly."
echo "=========================================================="
