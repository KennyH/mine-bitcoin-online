#!/bin/bash

set -e

show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

This script installs and configures Bitcoin Core on your system for
Mainnet, Testnet, and/or Regtest.
It is idempotent and can be run multiple times without overwriting existing
configuration or service files, unless the --force flag is used.

Options:
  --mainnet      Install and configure a mainnet Bitcoin node (default if no flag given and no other network specified)
  --testnet      Install and configure a testnet Bitcoin node
  --regtest      Install and configure a regtest Bitcoin node
  --both         Install and configure both mainnet and testnet nodes
  --all          Install and configure mainnet, testnet, and regtest nodes
  --force        Overwrite existing configuration and re-install binaries/services
  -h, --help     Show this help message and exit

Examples:
  $0 --mainnet
  $0 --testnet
  $0 --regtest
  $0 --both
  $0 --all
  $0 --all --force

EOF
}

# Default values
BITCOIN_VERSION="28.1"
INSTALL_MAINNET=false
INSTALL_TESTNET=false
INSTALL_REGTEST=false
FORCE=false

# Parse flags
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --mainnet) INSTALL_MAINNET=true ;;
        --testnet) INSTALL_TESTNET=true ;;
        --regtest) INSTALL_REGTEST=true ;;
        --both) INSTALL_MAINNET=true; INSTALL_TESTNET=true ;;
        --all) INSTALL_MAINNET=true; INSTALL_TESTNET=true; INSTALL_REGTEST=true ;;
        --force) FORCE=true ;;
        -h|--help) show_help; exit 0 ;;
        *) echo "Unknown parameter passed: $1"; show_help; exit 1 ;;
    esac
    shift
done

# Default to mainnet if no network flag is explicitly given
if ! $INSTALL_MAINNET && ! $INSTALL_TESTNET && ! $INSTALL_REGTEST; then
    INSTALL_MAINNET=true
fi

# Variables
USER_HOME=$(eval echo ~${SUDO_USER:-$USER})
BITCOIN_USER=${SUDO_USER:-$USER}
BITCOIN_MAINNET_DIR="$USER_HOME/.bitcoin"
BITCOIN_TESTNET_DIR="$USER_HOME/.bitcoin-testnet"
BITCOIN_REGTEST_DIR="$USER_HOME/.bitcoin-regtest" # New Regtest directory
BITCOIN_BIN_DIR="/usr/local/bin"
BITCOIN_TARBALL="bitcoin-${BITCOIN_VERSION}-aarch64-linux-gnu.tar.gz" # Assuming aarch64 for RPi 5
BITCOIN_URL="https://bitcoincore.org/bin/bitcoin-core-${BITCOIN_VERSION}/${BITCOIN_TARBALL}"

# --- Prerequisites ---
echo "Ensuring prerequisites are installed..."
sudo apt update
sudo apt install -y git build-essential libtool autotools-dev automake pkg-config libevent-dev bsdmainutils python3 libboost-all-dev libssl-dev libminiupnpc-dev libzmq3-dev wget
echo "Prerequisites installed."

# --- Download and Install Bitcoin Core ---
echo "Downloading and installing Bitcoin Core ${BITCOIN_VERSION}..."
if [ ! -f "$USER_HOME/$BITCOIN_TARBALL" ] || $FORCE; then
    cd "$USER_HOME"
    echo "Downloading Bitcoin Core tarball..."
    wget -N "$BITCOIN_URL"
    echo "Downloading checksums..."
    wget -N "https://bitcoincore.org/bin/bitcoin-core-${BITCOIN_VERSION}/SHA256SUMS"
    wget -N "https://bitcoincore.org/bin/bitcoin-core-${BITCOIN_VERSION}/SHA256SUMS.asc"
    echo "Verifying checksums..."
    sha256sum --ignore-missing -c SHA256SUMS
    if [ $? -ne 0 ]; then
        echo "Bitcoin Core binary verification failed. Exiting."
        exit 1
    fi
    echo "Extracting and installing binaries..."
    tar -xvf "$BITCOIN_TARBALL"
    sudo install -m 0755 -o root -g root -t $BITCOIN_BIN_DIR bitcoin-${BITCOIN_VERSION}/bin/*
    rm -rf "$USER_HOME/bitcoin-${BITCOIN_VERSION}"
    echo "Bitcoin Core binaries installed to $BITCOIN_BIN_DIR."
else
    echo "Bitcoin Core tarball already exists and --force not used. Skipping download/install."
fi

# --- Function to create config ---
# Takes network name (mainnet, testnet, regtest) and data directory
create_config() {
    local NETWORK=$1
    local DIR=$2
    local CONF_FILE="$DIR/bitcoin.conf"
    local RPC_USER=$(hostname) # Use hostname for RPC user
    local RPC_PASSWORD=$(openssl rand -hex 32) # Generate unique password
    local ZMQ_BLOCK_PORT
    local ZMQ_TX_PORT

    mkdir -p "$DIR"

    # Assign ZMQ ports based on network to avoid conflicts
    case "$NETWORK" in
        "mainnet")
            ZMQ_BLOCK_PORT=28334
            ZMQ_TX_PORT=28335
            ;;
        "testnet")
            ZMQ_BLOCK_PORT=28333 # Standard testnet ZMQ block
            ZMQ_TX_PORT=28332 # Standard testnet ZMQ tx
            ;;
        "regtest")
            ZMQ_BLOCK_PORT=18333 # Custom port for Regtest ZMQ block
            ZMQ_TX_PORT=18332 # Custom port for Regtest ZMQ tx
            ;;
        *)
            echo "Error: Unknown network '$NETWORK' passed to create_config."
            exit 1
            ;;
    esac


    if [ ! -f "$CONF_FILE" ] || $FORCE; then
        echo "Creating/Updating configuration for $NETWORK at $CONF_FILE"
        cat << EOF > "$CONF_FILE"
# Bitcoin Core configuration for ${NETWORK}
daemon=1
server=1
txindex=1
rpcuser=${RPC_USER}
rpcpassword=${RPC_PASSWORD}
rpcallowip=127.0.0.1
prune=0
dbcache=1024
maxconnections=20

# Enable ZMQ for block and transaction notifications
# Ports differ by network
zmqpubrawblock=tcp://127.0.0.1:${ZMQ_BLOCK_PORT}
zmqpubrawtx=tcp://127.0.0.1:${ZMQ_TX_PORT}
EOF
        # Add network specific line
        case "$NETWORK" in
            "testnet") echo "testnet=1" >> "$CONF_FILE" ;;
            "regtest") echo "regtest=1" >> "$CONF_FILE" ;;
            *) ;; # Mainnet requires no extra line
        esac

        echo "RPC Password for ${NETWORK} node: ${RPC_PASSWORD}" # Output the generated password - IMPORTANT TO SECURELY STORE THIS!
    else
        echo "Configuration for $NETWORK already exists at $CONF_FILE and --force not used. Skipping config creation."
        # Note: RPC password won't be printed again if config exists
    fi
    # Ensure the user running the script owns the data directory and config file
    sudo chown -R "$BITCOIN_USER:$BITCOIN_USER" "$DIR"
}

# --- Function to create systemd service ---
# Takes network name (mainnet, testnet, regtest) and data directory
create_service() {
    local NETWORK=$1
    local DIR=$2
    local CONF_FILE="$DIR/bitcoin.conf"
    local SERVICE_NAME # The name of the systemd service file (e.g., bitcoind.service)
    local DESCRIPTION_NAME # Name used in the Description line (e.g., Bitcoin daemon (testnet))

    case "$NETWORK" in
        "mainnet")
            SERVICE_NAME="bitcoind.service"
            DESCRIPTION_NAME="" # Default description uses no extra name
            ;;
        "testnet")
            SERVICE_NAME="bitcoind-testnet.service"
            DESCRIPTION_NAME=" (testnet)"
            ;;
        "regtest")
            SERVICE_NAME="bitcoind-regtest.service"
            DESCRIPTION_NAME=" (regtest)"
            ;;
        *)
            echo "Error: Unknown network '$NETWORK' passed to create_service."
            exit 1
            ;;
    esac

    local SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}"

    if [ ! -f "$SERVICE_FILE" ] || $FORCE; then
        echo "Creating/Updating systemd service for $NETWORK at $SERVICE_FILE"
        sudo bash -c "cat << EOF > $SERVICE_FILE
[Unit]
Description=Bitcoin daemon${DESCRIPTION_NAME}
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
        echo "Systemd service for $NETWORK created/updated."
        sudo systemctl daemon-reload
        sudo systemctl enable "$SERVICE_NAME"
        echo "Enabled $SERVICE_NAME. Attempting restart..."
        sudo systemctl restart "$SERVICE_NAME"
        echo "$SERVICE_NAME restarted. Waiting 10 seconds for daemon start..."
        sleep 10
        # Check service status (optional but helpful)
        # sudo systemctl status "$SERVICE_NAME" --no-pager
    else
        echo "Systemd service for $NETWORK already exists at $SERVICE_FILE and --force not used. Skipping service creation."
        echo "Attempting restart of existing $SERVICE_NAME..."
        sudo systemctl daemon-reload # Always reload daemon configs in case of subtle changes
        sudo systemctl restart "$SERVICE_NAME"
        echo "$SERVICE_NAME restarted. Waiting 10 seconds for daemon start..."
        sleep 10
    fi

     # Verify bitcoind is running and responsive
    if $($BITCOIN_BIN_DIR/bitcoin-cli -conf="$CONF_FILE" -datadir="$DIR" getblockchaininfo > /dev/null 2>&1); then
         echo "$NETWORK node is running and responsive."
    else
         echo "Warning: $NETWORK node may not be running or responsive. Check logs with 'sudo journalctl -u $SERVICE_NAME'."
    fi
}

# --- Setup Networks ---

# Mainnet setup
if $INSTALL_MAINNET; then
    echo "--- Setting up Mainnet ---"
    create_config "mainnet" "$BITCOIN_MAINNET_DIR"
    create_service "mainnet" "$BITCOIN_MAINNET_DIR"
    echo "Mainnet node setup complete."
    echo "--------------------------"
fi

# Testnet setup
if $INSTALL_TESTNET; then
    echo "--- Setting up Testnet ---"
    create_config "testnet" "$BITCOIN_TESTNET_DIR"
    create_service "testnet" "$BITCOIN_TESTNET_DIR"
    echo "Testnet node setup complete."
    echo "--------------------------"
fi

# Regtest setup
if $INSTALL_REGTEST; then
    echo "--- Setting up Regtest ---"
    create_config "regtest" "$BITCOIN_REGTEST_DIR"
    create_service "regtest" "$BITCOIN_REGTEST_DIR"
    echo "Regtest node setup complete."
    echo "--------------------------"
fi

echo "=========================================================="
echo "[x] Bitcoin Core Node installation and configuration is complete!"
echo "Selected networks:"
if $INSTALL_MAINNET; then
    echo "[x] Mainnet"
    echo "    Datadir: $BITCOIN_MAINNET_DIR"
    echo "    Config:  $BITCOIN_MAINNET_DIR/bitcoin.conf"
    echo "    Service: bitcoind.service"
fi
if $INSTALL_TESTNET; then
    echo "[x] Testnet"
    echo "    Datadir: $BITCOIN_TESTNET_DIR"
    echo "    Config:  $BITCOIN_TESTNET_DIR/bitcoin.conf"
    echo "    Service: bitcoind-testnet.service"
fi
if $INSTALL_REGTEST; then
    echo "[x] Regtest"
    echo "    Datadir: $BITCOIN_REGTEST_DIR"
    echo "    Config:  $BITCOIN_REGTEST_DIR/bitcoin.conf"
    echo "    Service: bitcoind-regtest.service"
fi
echo "[!] IMPORTANT: Securely store your RPC password(s) outputted during config creation."
echo "[!] BACKUP your wallet and important node data regularly."
echo "=========================================================="
