import requests
import json
import argparse
import os
import sys

def get_api_endpoint_from_json():
    """
    Retrieves the API Gateway endpoint URL from the 'tf_outputs.json' file.
    """
    try:
        script_dir = os.path.dirname(os.path.abspath(__file__))
        json_path = os.path.join(script_dir, 'tf_outputs.json')

        if not os.path.exists(json_path):
            print(f"Error: Output file not found at '{json_path}'", file=sys.stderr)
            print("Please run 'terraform output -json > tf_outputs.json' in the 'infra/tf' directory first.", file=sys.stderr)
            return None

        # Open the file with 'utf-16' encoding to handle PowerShell's default output format
        with open(json_path, 'r', encoding='utf-16') as f:
            outputs = json.load(f)
        
        endpoint = outputs.get('api_endpoint', {}).get('value')

        if not endpoint:
            print(f"Error: 'api_endpoint' not found in '{json_path}'.", file=sys.stderr)
            return None
        
        print(f"API Endpoint found: {endpoint}")
        return endpoint

    except json.JSONDecodeError:
        print(f"Error: Could not decode JSON from '{json_path}'. Is the file valid?", file=sys.stderr)
        return None
    except Exception as e:
        print(f"An unexpected error occurred while reading the output file: {e}", file=sys.stderr)
        return None

def send_book_request(endpoint, title, isbn, email, api_key):
    """
    Sends a book request to the specified API Gateway endpoint.
    """
    payload = {
        "title": title,
        "isbn": isbn,
        "requestEmail": email
    }
    headers = {
        'Content-Type': 'application/json',
        'x-api-key': api_key
    }

    print(f"\nSending POST request to: {endpoint}")
    print(f"Payload: {json.dumps(payload, indent=2)}")

    try:
        response = requests.post(endpoint, data=json.dumps(payload), headers=headers, timeout=10)
        
        print("\n--- Response ---")
        print(f"Status Code: {response.status_code}")
        
        try:
            print("Response Body:")
            print(json.dumps(response.json(), indent=2))
        except json.JSONDecodeError:
            print(f"Response Body (non-JSON): {response.text}")

    except requests.exceptions.RequestException as e:
        print(f"\nAn error occurred while sending the request: {e}", file=sys.stderr)

def main():
    """
    Main function to parse arguments and run the test.
    """
    parser = argparse.ArgumentParser(description="Send a book request to the deployed API Gateway.")
    parser.add_argument("--title", default="Optics", help="The title of the book.")
    parser.add_argument("--isbn", default="978-0133977226", help="The ISBN of the book.")
    parser.add_argument("--email", default="test@gmail.com", help="The email address for the request.")
    args = parser.parse_args()

    api_endpoint = get_api_endpoint_from_json()
    if not api_endpoint:
        sys.exit(1)

    # Load API Key from environment or .env file manually
    script_dir = os.path.dirname(os.path.abspath(__file__))
    env_path = os.path.join(script_dir, '.env')
    
    api_key = os.environ.get("API_KEY")
    if not api_key and os.path.exists(env_path):
        with open(env_path, 'r') as f:
            for line in f:
                if line.startswith("API_KEY="):
                    api_key = line.strip().split("=", 1)[1].strip('\'"')
                    break

    if not api_key:
         print("Error: API_KEY not found in environment variables or .env file.", file=sys.stderr)
         sys.exit(1)

    send_book_request(api_endpoint, args.title, args.isbn, args.email, api_key)

if __name__ == "__main__":
    main()