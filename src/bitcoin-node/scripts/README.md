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

## Disable Some Services
Assuming you're running the Node on a Raspberry Pi, some of these services can be disabled.

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