import json
import os
from openai import OpenAI
import concurrent.futures

# Initialize the OpenAI client
openai_api_key = os.environ.get("OPENAI_API_KEY")
if not openai_api_key:
     # In a real scenario, raise an exception or return an error response
     print("Error: OPENAI_API_KEY environment variable not set.")
     # For this demo, we'll proceed, but calls to OpenAI will fail

client = OpenAI(api_key=openai_api_key)

def extract_prompt_parts(prompt_template, user_message_text, placeholder="$$USER_MESSAGE$$"):
    """
    Extracts the system and user message parts from a prompt template
    and replaces the placeholder in the user message part.
    Assumes sections are delimited by '--- SYSTEM MESSAGE ---' and '--- USER MESSAGE ---'.
    """
    system_marker = "# --- SYSTEM MESSAGE ---"
    user_marker = "# --- USER MESSAGE ---"

    system_prompt = ""
    user_prompt_template = ""
    current_section = None

    # Split the template by lines
    lines = prompt_template.splitlines()

    for line in lines:
        if system_marker in line:
            current_section = "system"
            continue # Skip the marker line
        elif user_marker in line:
            current_section = "user_template"
            continue # Skip the marker line

        if current_section == "system":
            system_prompt += line + "\n"
        elif current_section == "user_template":
            user_prompt_template += line + "\n"

    # Remove leading/trailing whitespace and replace placeholder
    system_prompt = system_prompt.strip()
    user_prompt = user_prompt_template.strip().replace(placeholder, user_message_text)

    return system_prompt, user_prompt

def process_single_prompt(system_prompt, user_prompt, filename, client):
    """Helper function to process a single prompt with OpenAI."""
    try:
        print(f"Processing prompt: {filename}")
        # print(f"System Prompt:\n{system_prompt}") # Uncomment for debugging
        # print(f"User Prompt:\n{user_prompt}")     # Uncomment for debugging

        response = client.chat.completions.create(
            model="gpt-4o-mini", # fast & cheap; bump up if needed
            temperature=0,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_prompt}
            ],
            response_format={"type": "json_object"} # leverages structured outputs
        )
        result_content = response.choices[0].message.content

        # Attempt to parse the JSON response
        try:
            result_json = json.loads(result_content)
            # **NEW:** Return the entire parsed JSON object
            return {filename: result_json}
        except json.JSONDecodeError:
            print(f"Error decoding JSON response for {filename}: {result_content}")
            return {filename: {"error": "Invalid JSON response from OpenAI", "raw_response": result_content}}
        except Exception as json_parse_error:
            print(f"Unexpected error parsing JSON for {filename}: {json_parse_error}")
            return {filename: {"error": f"Unexpected JSON parse error: {json_parse_error}", "raw_response": result_content}}

    except Exception as e:
        print(f"Error processing prompt {filename} with OpenAI: {e}")
        return {filename: {"error": str(e)}} # Return error message on API call failure


def lambda_handler(event, context):
    # Assuming event is a valid POST request with a body containing message_text
    try:
        request_body = json.loads(event['body'])
        message_text = request_body['message_text'] # Will raise KeyError if message_text is missing
    except (KeyError, json.JSONDecodeError) as e:
        # Basic error handling for expected POST input issues for the demo
        return {
            "statusCode": 400,
            "headers": {"Content-Type": "application/json", "Access-Control-Allow-Origin": "*"},
            "body": json.dumps({"message": f"Invalid request body: {e}"})
        }
    except Exception as e:
         # Catch any other unexpected errors during body processing
         print(f"An unexpected error occurred during body processing: {e}")
         return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json", "Access-Control-Allow-Origin": "*"},
            "body": json.dumps({"message": f"An unexpected error occurred: {e}"})
        }


    prompts_dir = os.path.join(os.path.dirname(__file__), "prompts")
    placeholder = "$$USER_MESSAGE$$"
    prompt_files = [f for f in os.listdir(prompts_dir) if f.endswith(".txt")]

    if not prompt_files:
         return {
            "statusCode": 500, # Internal Server Error
            "headers": {"Content-Type": "application/json", "Access-Control-Allow-Origin": "*"},
            "body": json.dumps({"message": "No prompt files found in the 'prompts' directory."})
        }

    all_results = {} # Store results from all prompts

    # Process prompts in parallel
    with concurrent.futures.ThreadPoolExecutor() as executor:
        future_to_filename = {}
        for filename in prompt_files:
            filepath = os.path.join(prompts_dir, filename)
            try:
                with open(filepath, 'r') as f:
                    prompt_template = f.read()

                # Extract system and user parts and replace placeholder
                system_prompt, user_prompt = extract_prompt_parts(prompt_template, message_text, placeholder)

                # Submit the task to the thread pool
                future = executor.submit(process_single_prompt, system_prompt, user_prompt, filename, client)
                future_to_filename[future] = filename # Map future back to filename
            except Exception as e:
                print(f"Error preparing prompt {filename}: {e}")
                all_results[filename] = {"error": f"Error preparing prompt: {e}"}


        # Collect results as they complete
        for future in concurrent.futures.as_completed(future_to_filename):
            filename = future_to_filename[future]
            result_dict = future.result()
            all_results.update(result_dict)


    # Return the combined results
    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*"
        },
        "body": json.dumps(all_results)
    }
