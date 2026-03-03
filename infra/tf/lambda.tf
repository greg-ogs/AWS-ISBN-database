resource "aws_lambda_function" "producer_lambda" {
  filename         = "producer_lambda.zip"
  source_code_hash = filebase64sha256("producer_lambda.zip")
  function_name    = var.producer_lambda_name
  role             = aws_iam_role.producer_lambda_role.arn
  handler          = "main.lambda_handler"
  runtime          = "python3.12"

  environment {
    variables = {
      SQS_QUEUE_URL = aws_sqs_queue.book_queue.url
    }
  }
}

resource "aws_lambda_function" "consumer_lambda" {
  filename         = "consumer_lambda.zip"
  source_code_hash = filebase64sha256("consumer_lambda.zip")
  function_name    = var.consumer_lambda_name
  role             = aws_iam_role.consumer_lambda_role.arn
  handler          = "main.lambda_handler"
  runtime          = "python3.12"

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.book_table.name
    }
  }
}

resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.book_queue.arn
  function_name    = aws_lambda_function.consumer_lambda.arn
  batch_size       = 1

  depends_on = [aws_iam_role_policy_attachment.consumer_sqs_attach]
}

resource "aws_cloudwatch_log_group" "producer_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.producer_lambda.function_name}"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "consumer_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.consumer_lambda.function_name}"
  retention_in_days = 14
}
