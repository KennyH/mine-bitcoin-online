# sudo apt install python3-pip -y
# python3 -m venv ~/zmqtest
# source ~/zmqtest/bin/activate
# pip3 install pyzmq

# zmq_test.py
import zmq

context = zmq.Context()
socket = context.socket(zmq.SUB)
socket.connect("tcp://127.0.0.1:28334")  # Use 28333 for testnet blocks
socket.setsockopt_string(zmq.SUBSCRIBE, "")

print("Listening for new blocks...")
while True:
    block = socket.recv()
    print(f"Received new block (raw): {block.hex()[:64]}...")
