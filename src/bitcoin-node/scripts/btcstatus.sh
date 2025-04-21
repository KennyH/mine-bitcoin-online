#!/bin/bash

# This script requires 'bc' and 'jq' to be installed.
# You can install them using: sudo apt update && sudo apt install -y bc jq

# Ensure bc and jq are installed, provide guidance if not.
if ! command -v bc &> /dev/null || ! command -v jq &> /dev/null; then
    echo "Error: 'bc' and/or 'jq' are not installed."
    echo "Please install them using: sudo apt update && sudo apt install -y bc jq"
    exit 1
fi

show_help() {
    cat << EOF
Usage: $0 [OPTIONS]

This script is a wrapper around 'bitcoin-cli getblockchaininfo' that makes
the output easier to read. By default, it queries your mainnet node.

Options:
  --mainnet    Show mainnet status (default)
  --testnet    Show testnet status
  --regtest    Show regtest status
  -h, --help   Show this help message

Examples:
  $0           # Show mainnet status
  $0 --testnet # Show testnet status
  $0 --regtest # Show regtest status
  $0 --help    # Show this help message

Tip: Use with 'watch' to monitor progress:
  watch -n 5 $0
EOF
}

# Default configuration
NETWORK="mainnet" # Variable to track which network is selected
BITCOIN_CLI_BASE="bitcoin-cli"
BITCOIN_DATA_DIR="$HOME/.bitcoin"
BITCOIN_CONFIG_FILE="$HOME/.bitcoin/bitcoin.conf"

# Parse flags
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --mainnet)
            NETWORK="mainnet"
            BITCOIN_DATA_DIR="$HOME/.bitcoin"
            BITCOIN_CONFIG_FILE="$HOME/.bitcoin/bitcoin.conf"
            ;;
        --testnet)
            NETWORK="testnet"
            BITCOIN_DATA_DIR="$HOME/.bitcoin-testnet"
            BITCOIN_CONFIG_FILE="$HOME/.bitcoin-testnet/bitcoin.conf"
            ;;
        --regtest)
            NETWORK="regtest"
            BITCOIN_DATA_DIR="$HOME/.bitcoin-regtest"
            BITCOIN_CONFIG_FILE="$HOME/.bitcoin-regtest/bitcoin.conf"
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown parameter passed: $1"
            show_help
            exit 1
            ;;
    esac
    shift
done

# Construct the final bitcoin-cli command
BITCOIN_CLI="$BITCOIN_CLI_BASE -conf=$BITCOIN_CONFIG_FILE -datadir=$BITCOIN_DATA_DIR"

# Execute bitcoin-cli and check for errors
data=$($BITCOIN_CLI getblockchaininfo 2>&1)

# Check if the command failed (e.g., node not running, config missing)
if [[ $? -ne 0 ]]; then
    echo "Error querying $NETWORK node:"
    echo "$data" # Output the error message from bitcoin-cli
    echo "Please ensure your $NETWORK node is running and accessible with the correct configuration."
    exit 1
fi


# --- Process and format data ---

# Use jq to extract values. -r flag outputs raw strings.
blocks=$(jq -r '.blocks' <<< "$data")
headers=$(jq -r '.headers' <<< "$data")
difficulty=$(jq -r '.difficulty' <<< "$data")
verificationprogress=$(jq -r '.verificationprogress' <<< "$data")
initialblockdownload=$(jq -r '.initialblockdownload' <<< "$data")
size_on_disk=$(jq -r '.size_on_disk' <<< "$data")
pruned=$(jq -r '.pruned' <<< "$data")
pruneheight=$(jq -r '.pruneheight' <<< "$data")
time=$(jq -r '.time' <<< "$data") # Unix timestamp of the last block
mediantime=$(jq -r '.mediantime' <<< "$data") # Unix timestamp of the median time past

# Derived values
synced_headers=$([ "$headers" -eq "$blocks" ] && echo "Yes" || echo "No") # Simple check if headers match blocks

# Convert utc timestamps to Pacific Time (America/Los_Angeles)
# Handle potential empty or invalid timestamps gracefully
time_pst="N/A"
if [[ -n "$time" && "$time" != "null" && "$time" != "0" ]]; then # Also check for 0
    time_pst=$(TZ=America/Los_Angeles date -d "@$time" '+%Y-%m-%d %H:%M:%S %Z' 2>/dev/null) || time_pst="Invalid Timestamp"
fi

mediantime_pst="N/A"
if [[ -n "$mediantime" && "$mediantime" != "null" && "$mediantime" != "0" ]]; then # Also check for 0
    mediantime_pst=$(TZ=America/Los_Angeles date -d "@$mediantime" '+%Y-%m-%d %H:%M:%S %Z' 2>/dev/null) || mediantime_pst="Invalid Timestamp"
fi

# Convert size_on_disk to GB with 3 decimals
size_on_disk_gb="N/A"
if [[ -n "$size_on_disk" && "$size_on_disk" != "null" ]]; then
    # bc expects a number, check if size_on_disk is numeric before piping
    if [[ "$size_on_disk" =~ ^[0-9]+$ ]]; then
        size_on_disk_gb=$(echo "scale=3; $size_on_disk/1073741824" | bc)
    else
        size_on_disk_gb="Invalid Size"
    fi
fi

# Format difficulty - add thousands separators
formatted_difficulty="N/A"
if [[ -n "$difficulty" && "$difficulty" != "null" ]]; then
    # Use printf's ability to add thousands separators. Requires locale to be set.
    LC_NUMERIC="C" printf -v formatted_difficulty "%'.f" "$difficulty" 2>/dev/null || formatted_difficulty="Invalid Difficulty"
fi

# Format verificationprogress as percentage
verificationprogress_pct="N/A"
if [[ -n "$verificationprogress" && "$verificationprogress" != "null" ]]; then
     # Check if verificationprogress is numeric
    if [[ "$verificationprogress" =~ ^[0-9]*\.?[0-9]+$ ]]; then
         # Multiply by 100 and format with 2 decimal places using bc
        verificationprogress_pct=$(echo "scale=2; $verificationprogress * 100" | bc)
        verificationprogress_pct="${verificationprogress_pct}%"
    else
        verificationprogress_pct="Invalid Progress"
    fi
fi

# Format pruneheight (if pruning is enabled)
formatted_pruneheight="N/A (Pruning Disabled)"
if [[ "$pruned" == "true" && -n "$pruneheight" && "$pruneheight" != "null" ]]; then
    # Check if pruneheight is numeric
    if [[ "$pruneheight" =~ ^[0-9]+$ ]]; then
         LC_NUMERIC="C" printf -v formatted_pruneheight "%'.f" "$pruneheight" 2>/dev/null || formatted_pruneheight="Invalid Height"
    else
        formatted_pruneheight="Invalid Height"
    fi
fi

# Format initialblockdownload
initialblockdownload_status="N/A"
if [[ "$initialblockdownload" == "true" ]]; then
    initialblockdownload_status="Yes"
elif [[ "$initialblockdownload" == "false" ]]; then
     initialblockdownload_status="No"
fi

# --- Output Formatted Data (Ordered similar to getblockchaininfo) ---

echo "Bitcoin Core Node Status ($NETWORK):"
echo "--------------------------------------------------"
# Set locale for printf thousands separators just for the output block
LC_NUMERIC="C"
printf "%-25s %s\n" "Blocks:" "$blocks"
printf "%-25s %s\n" "Headers:" "$headers"
printf "%-25s %s\n" "Synced Headers:" "$synced_headers"
printf "%-25s %s\n" "Difficulty:" "$formatted_difficulty"
printf "%-25s %s\n" "Verification Progress:" "$verificationprogress_pct"
printf "%-25s %s\n" "Initial Block Download:" "$initialblockdownload_status"
printf "%-25s %s\n" "Size on Disk:" "${size_on_disk_gb} GB" # Add GB here
printf "%-25s %s\n" "Prune Height:" "$formatted_pruneheight"
printf "%-25s %s\n" "Last Block Time (PST):" "$time_pst"
printf "%-25s %s\n" "Median Time (PST):" "$mediantime_pst"
echo "--------------------------------------------------"
