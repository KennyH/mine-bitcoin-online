import json
import os

def lambda_handler(event, context):
    print("Received event: " + json.dumps(event, indent=2))

    prompts_content = {}
    prompts_dir = os.path.join(os.path.dirname(__file__), "prompts")

    # Read content of each prompt file (existing logic)
    if os.path.exists(prompts_dir):
        for filename in os.listdir(prompts_dir):
            if filename.endswith(".txt"):
                filepath = os.path.join(prompts_dir, filename)
                with open(filepath, 'r') as f:
                    prompts_content[filename] = f.read()
    else:
        print("Prompts directory not found!")

    message_text = None
    if event.get('httpMethod') == 'POST' and event.get('body'):
        try:
            request_body = json.loads(event['body'])
            message_text = request_body.get('message_text')
            print(f"Received message_text: {message_text}")
        except json.JSONDecodeError:
            print("Failed to decode JSON body")

    # Basic response for the demo, including prompt content and received message_text
    response_body = {
        "message": "Hello from your Vulnerability MVP Lambda!",
        "input_event": event, # Include the full event for debugging
        "prompts_loaded": prompts_content,
        "received_message_text": message_text # Include the extracted message_text
    }

    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*" # Allow requests from anywhere for the demo
        },
        "body": json.dumps(response_body)
    }
