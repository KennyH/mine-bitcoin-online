#!/bin/bash

#sudo apt install -y bc jq

# This script is just a wrapper around getblockchaininfo, that makes
# it easier to read. You can call it once (after chmod +x'ing it),
# and/or call it via `watch -n 5 ./btcstatus.sh` to track the progress.

data=$(bitcoin-cli getblockchaininfo)

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
# The concept of difficulty is x times the original difficulty set
# by Satoshi, so it is useful to format it (e.g. now it is 20
# trillion times more difficult) 
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