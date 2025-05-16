import json
import os

def lambda_handler(event, context):
    print("Received event: " + json.dumps(event, indent=2))

    prompts_content = {}
    prompts_dir = os.path.join(os.path.dirname(__file__), "prompts")

    if os.path.exists(prompts_dir):
        for filename in os.listdir(prompts_dir):
            if filename.endswith(".txt"):
                filepath = os.path.join(prompts_dir, filename)
                with open(filepath, 'r') as f:
                    prompts_content[filename] = f.read()
    else:
        print("Prompts directory not found!")

    response_body = {
        "message": "Hello from your Vulnerability MVP Lambda!",
        "input": event,
        "prompts_loaded": prompts_content
    }

    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*" # Allow requests from anywhere for the demo
        },
        "body": json.dumps(response_body)
    }
