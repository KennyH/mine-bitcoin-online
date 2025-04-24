# Notes
Consider doing the following (for security)

## Enable UFW (Uncomplicated Firewall) 
```
sudo apt install ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw enable

#list
sudo ufw status verbose
sudo ss -tulnp
```

If port forwarding is desired to be a public node:
```
#mainnet
sudo ufw allow 8333

#testnet
sudo ufw allow 18332
```

# Automatic Security Updates

using unattended-upgrades:
```
sudo apt update
sudo apt install unattended-upgrades
sudo dpkg-reconfigure --priority=low unattended-upgrades
```

# Check for new versions of Bitcoin Core

- check on github for the new [releases](https://github.com/bitcoin/bitcoin/releases)
- subscribe to Bitcoin Core Org on [X](https://x.com/bitcoincoreorg)

# Setup a wallet interface

Unfortunately, I couldn't get a stable/quick instance of Sparrow, or Specture to exist on the pi while running as a node. So instead, I chose to run a seperate docker instance of Specter on a NAS system I have locally.

## Add firewall (ufw) rules for RPC ports to the NAS

```
NAS_IP="192.168.5.X" # Replace with NAS IP

# Allow Mainnet RPC from NAS
sudo ufw allow from $NAS_IP to any port 8332 proto tcp comment 'Allow Mainnet RPC from NAS'

# Allow Testnet RPC from NAS
sudo ufw allow from $NAS_IP to any port 18332 proto tcp comment 'Allow Testnet RPC from NAS'

# Allow Regtest RPC from NAS
sudo ufw allow from $NAS_IP to any port 18443 proto tcp comment 'Allow Regtest RPC from NAS'
```

## Update bitcoin.conf

Add relevant lines to conf files for all three node services (bitcoin.confg):
```
rpcallowip=127.0.0.1
rpcallowip=192.168.5.X # Replace with NAS IP
```

After updating each config, you need to restart the services.

Configs should be at:
- /home/pi/.bitcoin/bitcoin.conf
- /home/pi/.bitcoin-testnet/bitcoin.conf
- /home/pi/.bitcoin-regtest/bitcoin.conf

Other stuff needed to be updated, so I will include it here...

### Update config for Mainnet

```
# Bitcoin Core basic configuration
#daemon=1
server=1
txindex=1
rpcuser=piBtcNode01
rpcpassword=REPLACE_WITH_PASSWORD
rpcallowip=127.0.0.1
rpcallowip=192.168.X.X
rpcbind=192.168.Y.Y
rpcbind=127.0.0.1
rpcbind=0.0.0.0:8332
prune=0
dbcache=1024
maxconnections=20
disablewallet=0

# Enable ZMQ for block and transaction notifications
zmqpubrawblock=tcp://127.0.0.1:28334
zmqpubrawtx=tcp://127.0.0.1:28335

# Connect with port: 8332
```

### Update config for Testnet

```
# Bitcoin Core basic configuration

# Bitcoin Core testnet configuration

# Global settings (apply to all networks unless overridden)
server=1
txindex=1
prune=0
dbcache=1024 # Adjust as needed for testnet
maxconnections=20
disablewallet=0

# Network identifier (can be global)
testnet=1

# Testnet specific network settings
[test]
rpcuser=piBtcNode01-testnet
rpcpassword=REPLACE_WITH_PASSWORD
rpcallowip=127.0.0.1
rpcallowip=192.168.X.X  # Allow NAS IP
rpcbind=192.168.Y.Y     # Listen on Pi's LAN IP for testnet
rpcbind=127.0.0.1       # Listen on loopback for testnet

# ZMQ ports are network specific, place them here too
zmqpubrawblock=tcp://127.0.0.1:28333
zmqpubrawtx=tcp://127.0.0.1:28332

# Connect with port: 18332
```

### Update config for Regtest

```
# Bitcoin Core regtest configuration

# Global settings
server=1
txindex=1
prune=0
dbcache=100 # Regtest needs much less cache
maxconnections=10 # Regtest usually needs fewer connections
disablewallet=0

# Network identifier
regtest=1

# Regtest specific network settings
[regtest]
rpcuser=piBtcNode01-regtest
rpcpassword=REPLACE_WITH_PASSWORD
rpcallowip=127.0.0.1
rpcallowip=192.168.X.X  # Allow NAS IP
rpcbind=192.168.Y.Y     # Listen on Pi's LAN IP for regtest
rpcbind=127.0.0.1       # Listen on loopback for regtest

# ZMQ ports are network specific
zmqpubrawblock=tcp://127.0.0.1:18333
zmqpubrawtx=tcp://127.0.0.1:18332

# Connect with port: 18443
```

### Restart
```
# Restart mainnet node
sudo systemctl restart bitcoind.service

# Restart testnet node
sudo systemctl restart bitcoind-testnet.service

# Restart regtest node
sudo systemctl restart bitcoind-regtest.service
```

# Disable Some Services
If running the Node on a Raspberry Pi, some services can be disabled.

## List Services
```
sudo systemctl list-units --type=service
```

## Disable
(I didn't want these on my setup)
```
sudo systemctl disable --now avahi-daemon
sudo systemctl disable --now bluetooth
sudo systemctl disable --now ModemManager
```
