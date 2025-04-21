# sudo apt install python3-pip -y
# python3 -m venv ~/zmqtest
# source ~/zmqtest/bin/activate
# pip3 install pyzmq python-bitcoinlib

#!/usr/bin/env python3

import zmq
import argparse
import sys
import hashlib

def parse_arguments():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(
        description="Listen to Bitcoin Core ZMQ for block notifications on different networks."
    )
    group = parser.add_mutually_exclusive_group()
    group.add_argument(
        "--mainnet", action="store_true", help="Listen to Mainnet ZMQ (default)"
    )
    group.add_argument("--testnet", action="store_true", help="Listen to Testnet ZMQ")
    group.add_argument("--regtest", action="store_true", help="Listen to Regtest ZMQ")

    # Set default to mainnet if no flag is given
    args = parser.parse_args()
    if not any([args.mainnet, args.testnet, args.regtest]):
        args.mainnet = True

    return args

def get_zmq_port(args):
    """Determines the ZMQ port based on selected network."""
    if args.mainnet:
        return 28334, "Mainnet" # Mainnet rawblock port
    elif args.testnet:
        return 28333, "Testnet" # Testnet rawblock port
    elif args.regtest:
        return 18333, "Regtest" # Regtest rawblock port
    return None, None

if __name__ == "__main__":
    args = parse_arguments()
    zmq_port, network_name = get_zmq_port(args)

    if zmq_port is None:
        print("Error: Could not determine ZMQ port for the selected network.")
        sys.exit(1)

    zmq_address = f"tcp://127.0.0.1:{zmq_port}"
    context = zmq.Context()
    socket = context.socket(zmq.SUB)

    try:
        print(f"Attempting to connect to {network_name} ZMQ at {zmq_address}...")
        socket.connect(zmq_address)

        # Subscribe to 'rawblock' topic.
        # ZMQ topics are prefixes. This subscribes to messages starting with "rawblock".
        # bitcoind sends messages in multipart format: topic, data
        socket.setsockopt_string(zmq.SUBSCRIBE, "rawblock")

        print(f"Successfully connected and subscribed to 'rawblock' for {network_name}. Waiting for notifications...")

        error_count, MAX_ERRORS = 0, 3

        while True:
            if error_count >= MAX_ERRORS:
                print(f"Too many errors: {error_count}. Aborting.")
                break
            # Receive multipart message: topic and data
            message = socket.recv_multipart()
            if len(message) != 2:
                print(f"[{network_name}] Received unexpected ZMQ message format: {message}")
                error_count += 1
                continue
            topic, block_data = message
            # print(f"Received topic: {topic.decode()}")

            if topic == b"rawblock":
                # The 'rawblock' message contains the full block bytes.
                # The block header is the first 80 bytes.
                # The block hash is the double SHA256 of the header, displayed little-endian.
                if len(block_data) >= 80:
                    header = block_data[:80]
                    # Calculate the block hash (double SHA256 of the header)
                    hash1 = hashlib.sha256(header).digest()
                    block_hash_bytes = hashlib.sha256(hash1).digest()
                    # Reverse bytes for standard big-endian hexadecimal display
                    block_hash_display = block_hash_bytes[::-1].hex()

                    print(f"[{network_name}] Received new block. Hash: {block_hash_display}")
                    error_count = 0 #reset counter
                else:
                    print(f"[{network_name}] Received incomplete rawblock data.")
                    error_count += 1
            # add elif topic == b"rawtx": ... for transactions


    except zmq.core.error.ZMQError as e:
        print(f"\nZMQ Error connecting or receiving: {e}")
        print(f"Please ensure the {network_name} bitcoind instance is running and its ZMQ interface (zmqpubrawblock) is enabled on port {zmq_port} and accessible.")
        sys.exit(1)
    except KeyboardInterrupt:
        print("\nListening stopped by user.")
    finally:
        if 'socket' in locals() and not socket.closed:
             socket.close()
        if 'context' in locals() and not context.closed:
             context.term()
        print("ZMQ socket closed and context terminated.")


