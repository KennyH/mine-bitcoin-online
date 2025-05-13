# Setup Raspberry Pi Node

- After setting up your device (install SSD, OS, etc.), copy over the scripts in this folder and chmod +x them.
- The `setup-bitcoin-core.sh` script should install everything you need.
- The `btcstatus.sh` script is a wrapper around the bitcoin-cli that better formats the output.


## AWS CLI Setup and Configuration for IoT Core

You need to perform the following steps:

**Prerequisite:** You must have already created and configured your AWS IoT Core resources (IoT Thing, Certificate, Private Key, Policy, IAM Role, and Role Alias) using Terraform or the AWS Management Console.

1.  **Transfer AWS IoT Credentials to the Pi:**
    Securely transfer the following files from your AWS IoT Core setup to your Raspberry Pi. Store them in a secure location accessible by the user running the Bitcoin monitoring script (e.g., `/home/pi/.aws-iot-credentials/`):

    *   Your IoT device certificate file (`<your_certificate_id>-certificate.pem.crt`)
    *   Your IoT device private key file (`<your_certificate_id>-private.pem.key`)
    *   The Amazon Trust Services (ATS) root CA certificate (`AmazonRootCA1.pem`). You can download this from the AWS IoT Core console or from the AWS documentation.

    ```bash
    # Example using scp (replace with your actual filenames and paths)
    scp /path/to/your/certificate.pem.crt pi@your_pi_ip:/home/pi/.aws-iot-credentials/
    scp /path/to/your/private.pem.key pi@your_pi_ip:/home/pi/.aws-iot-credentials/
    scp /path/to/your/AmazonRootCA1.pem pi@your_pi_ip:/home/pi/.aws-iot-credentials/
    ```

    **Ensure strict permissions on these files to protect your credentials.** The user running the script should be the owner, and permissions should prevent others from reading or writing to them.

    ```bash
    # Example setting permissions
    chmod 600 /home/pi/.aws-iot-credentials/*
    ```

2.  **Configure AWS CLI for IoT Credentials Provider:**
    The AWS CLI can be configured to use the IoT Credentials Provider to obtain temporary credentials. You will need to set the following environment variables when running AWS CLI commands or in a script that will use the AWS CLI:

    *   `AWS_REGION`: Your AWS region (e.g., `us-west-2`).
    *   `AWS_IOT_THING_NAME`: The name of your IoT Thing (e.g., `piBtcNode01`).
    *   `AWS_IOT_CREDENTIALS_ENDPOINT`: Your AWS IoT Core Credentials Endpoint. You can find this in the AWS IoT Core console under "Settings" -> "Device data endpoints". It will be in the format `xxxxxxxxxxxxx-ats.iot.your-region.amazonaws.com`.
    *   `AWS_IOT_CERTIFICATE_ARN`: The ARN of your IoT certificate. You can get this from the output of your Terraform module or the AWS IoT Core console.
    *   `AWS_IOT_PRIVATE_KEY_PATH`: The absolute path to your private key file on the Pi (e.g., `/home/pi/.aws-iot-credentials/<your_certificate_id>-private.pem.key`).
    *   `AWS_IOT_CERTIFICATE_PATH`: The absolute path to your certificate file on the Pi (e.g., `/home/pi/.aws-iot-credentials/<your_certificate_id>-certificate.pem.crt`).
    *   `AWS_CA_BUNDLE`: The absolute path to the Amazon Root CA certificate file on the Pi (e.g., `/home/pi/.aws-iot-credentials/AmazonRootCA1.pem`).
    *   `AWS_ROLE_ARN`: The ARN of the IAM Role that your IoT policy allows you to assume via the Role Alias. This is the role with permissions to interact with other AWS services (S3, SQS, etc.).
    *   `AWS_ROLE_SESSION_NAME`: A name for the session (e.g., `pi-miner-session`).

    **Example of setting environment variables before an AWS CLI command:**

    ```bash
    export AWS_REGION="your-aws-region" # e.g., us-west-2
    export AWS_IOT_THING_NAME="piBtcNode01"
    export AWS_IOT_CREDENTIALS_ENDPOINT="xxxxxxxxxxxxx-ats.iot.your-region.amazonaws.com"
    export AWS_IOT_CERTIFICATE_ARN="arn:aws:iot:your-region:your-account-id:cert/your_certificate_id"
    export AWS_IOT_PRIVATE_KEY_PATH="/home/pi/.aws-iot-credentials/your_certificate_id-private.pem.key"
    export AWS_IOT_CERTIFICATE_PATH="/home/pi/.aws-iot-credentials/your_certificate_id-certificate.pem.crt"
    export AWS_CA_BUNDLE="/home/pi/.aws-iot-credentials/AmazonRootCA1.pem"
    export AWS_ROLE_ARN="arn:aws:iam::your-account-id:role/YourIotAssumedRole"
    export AWS_ROLE_SESSION_NAME="pi-miner-session"

    # Now you can run AWS CLI commands that will use temporary credentials obtained via IoT Core
    # For example, to publish a message to an IoT topic:
    aws iot-data publish --topic "pi-miner/mainnet/new-block" --payload "{\"message\": \"New block detected\"}"
    ```

3.  **Verify AWS CLI Configuration:**
    To test if the AWS CLI is configured correctly to use the IoT Credentials Provider and obtain temporary credentials, you can try a command that requires credentials:

    ```bash
    # Assuming environment variables from step 2 are set
    aws sts get-caller-identity
    ```

    This command should return information about the assumed IAM role, indicating that the IoT Credentials Provider successfully fetched temporary credentials. If it fails, double-check your environment variables, certificate/key paths, IoT policy permissions, IAM role trust policy, and Role Alias configuration.


## Notes
Consider doing the following (for security)

### Enable UFW (Uncomplicated Firewall) 
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

### Automatic Security Updates

using unattended-upgrades:
```
sudo apt update
sudo apt install unattended-upgrades
sudo dpkg-reconfigure --priority=low unattended-upgrades
```

### Check for new versions of Bitcoin Core

- check on github for the new [releases](https://github.com/bitcoin/bitcoin/releases)
- subscribe to Bitcoin Core Org on [X](https://x.com/bitcoincoreorg)

### Setup a wallet interface

Unfortunately, I couldn't get a stable/quick instance of Sparrow, or Specture to exist on the pi while running as a node. So instead, I chose to run a seperate docker instance of Specter on a NAS system I have locally.

### Add firewall (ufw) rules for RPC ports to the NAS

```
NAS_IP="192.168.Y.X" # Replace with NAS IP

# Allow Mainnet RPC from NAS
sudo ufw allow from $NAS_IP to any port 8332 proto tcp comment 'Allow Mainnet RPC from NAS'

# Allow Testnet RPC from NAS
sudo ufw allow from $NAS_IP to any port 18332 proto tcp comment 'Allow Testnet RPC from NAS'

# Allow Regtest RPC from NAS
sudo ufw allow from $NAS_IP to any port 18443 proto tcp comment 'Allow Regtest RPC from NAS'
```

### Update bitcoin.conf

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

### Disable Some Services
If running the Node on a Raspberry Pi, some services can be disabled.

### List Services
```
sudo systemctl list-units --type=service
```

### Disable
(I didn't want these on my setup)
```
sudo systemctl disable --now avahi-daemon
sudo systemctl disable --now bluetooth
sudo systemctl disable --now ModemManager
```
