# AWS ISBN Database Project

This project implements a serverless architecture on AWS to process book requests. It allows users to submit a book request (via ISBN) through an API Gateway, which triggers a producer Lambda function to send the request to an SQS queue. A consumer Lambda function then processes the message, fetches additional book details from the Open Library API, and stores the result in a DynamoDB table.

[!Note]
No GUI is available by the moment.
## Architecture Overview

The system consists of the following AWS components:

1.  **API Gateway**: Exposes a REST API endpoint (`/books`) to accept POST requests.
2.  **Producer Lambda**: Triggered by the API Gateway. It validates the request and sends a message to an SQS queue.
3.  **Amazon SQS**: Decouples the producer and consumer. It holds the book requests until they are processed.
4.  **Consumer Lambda**: Triggered by SQS messages. It retrieves book details from the Open Library API and saves the data to DynamoDB.
5.  **Amazon DynamoDB**: Stores the processed book requests and their details.

## Project Structure

*   `consumer_lambda/`: Contains the Python code for the consumer Lambda function.
*   `producer_lambda/`: Contains the Python code for the producer Lambda function.
*   `infra/tf/`: Contains the Terraform configuration files for provisioning the AWS infrastructure.
*   `build_lambdas.sh`: A shell script to build the deployment packages for the Lambda functions.

## Prerequisites

*   AWS CLI configured with appropriate permissions.
*   Terraform installed or a container with Terraform installed (dockerfile in infra/containers/tf).
*   Python 3.12 installed (For the test_api.py script).
*   `zip` utility installed (for packaging Lambdas).

## Deployment Instructions

1.  **Build Lambda Packages**:
    Run the build script to create the ZIP files for the Lambda functions.
    ```bash
    ./build_lambdas.sh
    ```
    This will create `producer_lambda.zip` and `consumer_lambda.zip` in the `infra/tf/` directory.

2.  **Initialize Terraform Manually**:
    Navigate to the Terraform directory.
    ```bash
    cd infra/tf
    terraform init
    ```
    or with a terraform docker container.
    ```powershell
    docker run --rm -v .\infra\tf\:/app user/terraform:latest
    ```

3.  **Deploy Infrastructure**:
    Apply the Terraform configuration to create the resources in AWS.
    ```bash
    terraform apply
    ```
    Confirm the action by typing `yes` when prompted.

    or from the docker container.

    ```powershell
    docker run --rm -v .\infra\tf\:/app --env-file .\infra\tools\.env user/terraform:latest apply -auto-approve
    ```

4.  **Note the API Endpoint**:
    After a successful deployment, Terraform will output the `api_endpoint`. You will use this URL to send requests.

    ```powershell
    docker run --rm -v .\infra\tf\:/app --env-file .\infra\tools\.env user/terraform:latest output -json > tf_outputs.json
    ```

## Usage

To submit a book request, send a POST request to the API endpoint with a JSON body containing `title`, `isbn`, and `requestEmail`.
