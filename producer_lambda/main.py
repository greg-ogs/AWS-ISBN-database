# Producer lambda file
import json
import os
import boto3
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

sqs = boto3.client('sqs')

try:
    SQS_QUEUE_URL = os.environ['SQS_QUEUE_URL']
except KeyError:
    logger.error("Fatal: SQS_QUEUE_URL environment variable not set!")
    raise

def lambda_handler(event, context):
    """
    Handles book requests from an API Gateway endpoint.

    - Validates the incoming JSON data for required fields.
    - Sends the validated data to an SQS queue for processing.
    """
    logger.info(f"Received event: {json.dumps(event)}")

    try:
        # Parse the request body from the API Gateway event
        try:
            body = json.loads(event.get('body', '{}'))
        except (json.JSONDecodeError, TypeError):
            logger.error("Request body is not valid JSON.")
            return {
                'statusCode': 400,
                'body': json.dumps({'message': 'Invalid JSON format in request body.'})
            }

        # Validate the required fields
        title = body.get('title')
        isbn = body.get('isbn')
        request_email = body.get('requestEmail')

        if not all([title, isbn, request_email]):
            logger.warning(f"Validation failed: missing required fields. Body: {body}")
            return {
                'statusCode': 400,
                'body': json.dumps({'message': 'Missing required fields: "title", "isbn", and "requestEmail".'})
            }

        message_body = json.dumps({
            'title': title,
            'isbn': isbn,
            'requestEmail': request_email
        })

        sqs.send_message(
            QueueUrl=SQS_QUEUE_URL,
            MessageBody=message_body
        )
        logger.info("Message sent successfully to SQS.")

        # Return a success response to the caller
        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'Book request received and sent for processing.'})
        }

    except Exception as e:
        logger.error(f"An unexpected error occurred: {str(e)}")
        # Return a generic server error for security
        return {
            'statusCode': 500,
            'body': json.dumps({'message': 'An internal server error occurred.'})
        }
