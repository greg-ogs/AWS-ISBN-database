import json
import os
import boto3
import requests
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS DynamoDB and get the table name from environment variables
dynamodb = boto3.resource('dynamodb')
try:
    TABLE_NAME = os.environ['DYNAMODB_TABLE_NAME']
    table = dynamodb.Table(TABLE_NAME)
except KeyError:
    logger.error("DYNAMODB_TABLE_NAME environment variable not set")
    raise

OPEN_LIBRARY_API_URL = "https://openlibrary.org/api/books"

def get_book_details(isbn):
    """
    Fetches additional book details from the Open Library API using ISBN.
    """
    params = {'bibkeys': f'ISBN:{isbn}', 'format': 'json', 'jscmd': 'data'}
    try:
        logger.info(f"Querying Open Library API with ISBN='{isbn}'")
        response = requests.get(OPEN_LIBRARY_API_URL, params=params, timeout=5)
        response.raise_for_status()
        
        data = response.json()
        book_key = f'ISBN:{isbn}'

        if book_key in data:
            book_doc = data[book_key]
            
            # Extract details
            publishers = [p['name'] for p in book_doc.get('publishers', [])]
            authors = [a['name'] for a in book_doc.get('authors', [])]

            return {
                'api_title': book_doc.get('title'),
                'authors': authors,
                'publish_date': book_doc.get('publish_date'),
                'publishers': publishers,
                'number_of_pages': book_doc.get('number_of_pages'),
            }
        else:
            logger.warning(f"Book with ISBN {isbn} not found in Open Library API.")
            return {}
            
    except requests.exceptions.RequestException as e:
        logger.error(f"Error calling Open Library API: {e}")
        return {}

def lambda_handler(event, context):
    """
    Processes book request messages from an SQS queue.
    - Fetches additional book data from an external API using the ISBN.
    - Stores the retrieved information in a DynamoDB table.
    """
    logger.info(f"Received {len(event.get('Records', []))} messages from SQS.")

    for record in event.get('Records', []):
        try:
            message_id = record['messageId']
            body_str = record.get('body')
            if not body_str:
                logger.warning(f"Skipping record {message_id} with empty body.")
                continue

            # SQS message body from JSON structure
            book_request = json.loads(body_str)
            title = book_request.get('title')
            isbn = book_request.get('isbn')
            request_email = book_request.get('requestEmail')

            if not all([title, isbn, request_email]):
                logger.warning(f"Skipping record {message_id} due to missing fields.")
                continue

            # Find information from the external API using ISBN
            additional_details = get_book_details(isbn)

            # Combine
            item_to_store = {
                'id': message_id,
                'request_title': title,
                'request_isbn': isbn,
                'request_email': request_email,
                **additional_details
            }

            table.put_item(Item=item_to_store)
            logger.info(f"Successfully processed and stored book request {message_id}.")

        except json.JSONDecodeError:
            logger.error(f"Failed to decode JSON for message: {record.get('messageId')}")
        except Exception as e:
            logger.error(f"Failed to process message {record.get('messageId')}: {e}")

    return {
        'statusCode': 200,
        'body': json.dumps('Processing complete.')
    }
