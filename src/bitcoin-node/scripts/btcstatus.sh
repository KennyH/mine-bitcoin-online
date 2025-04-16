#!/bin/bash

#sudo apt install -y bc jq

show_help() {
    cat << EOF
Usage: $0 [--testnet] [--help|-h]

This script is a wrapper around 'bitcoin-cli getblockchaininfo' that makes
the output easier to read. By default, it queries your mainnet node.
Use --testnet to query your testnet node.

Examples:
  $0           # Show mainnet status
  $0 --testnet # Show testnet status
  $0 --help    # Show this help message

Tip: Use with 'watch' to monitor progress:
  watch -n 5 $0
EOF
}

# Default to mainnet
BITCOIN_CLI="bitcoin-cli -conf=$HOME/.bitcoin/bitcoin.conf -datadir=$HOME/.bitcoin"

# Parse flags
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    show_help
    exit 0
elif [[ "$1" == "--testnet" ]]; then
    BITCOIN_CLI="bitcoin-cli -conf=$HOME/.bitcoin-testnet/bitcoin.conf -datadir=$HOME/.bitcoin-testnet"
    shift
fi

data=$($BITCOIN_CLI getblockchaininfo)

time=$(jq '.time' <<< "$data")
mediantime=$(jq '.mediantime' <<< "$data")
size_on_disk=$(jq '.size_on_disk' <<< "$data")
difficulty=$(jq '.difficulty' <<< "$data")

# Convert utc timestamps to Pacific Time (America/Los_Angeles)
time_pst=$(TZ=America/Los_Angeles date -d @"$time" '+%Y-%m-%d %H:%M:%S %Z')
mediantime_pst=$(TZ=America/Los_Angeles date -d @"$mediantime" '+%Y-%m-%d %H:%M:%S %Z')

# Convert size_on_disk to GB with 3 decimals
size_on_disk_gb=$(echo "scale=3; $size_on_disk/1073741824" | bc)

# Format difficulty
integer_part=$(echo "$difficulty" | cut -d'.' -f1)
decimal_part=$(echo "$difficulty" | cut -d'.' -f2)

formatted_integer=$(printf "%'d" "$integer_part")

if [[ -n "$decimal_part" && "$decimal_part" != "0" ]]; then
    formatted_difficulty="${formatted_integer}.${decimal_part}"
else
    formatted_difficulty="${formatted_integer}"
fi

# Output:
jq --arg time "$time_pst" \
   --arg mediantime "$mediantime_pst" \
   --arg size_on_disk "${size_on_disk_gb} GB" \
   --arg difficulty "$formatted_difficulty" \
   '.time=$time | .mediantime=$mediantime | .size_on_disk=$size_on_disk | .difficulty=$difficulty' <<< "$data"
