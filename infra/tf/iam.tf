resource "aws_iam_role" "producer_lambda_role" {
  name = "producer_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "producer_lambda_basic" {
  role       = aws_iam_role.producer_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "producer_sqs_policy" {
  name        = "producer_sqs_policy"
  description = "Allow sending messages to SQS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sqs:SendMessage"
        ]
        Effect   = "Allow"
        Resource = aws_sqs_queue.book_queue.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "producer_sqs_attach" {
  role       = aws_iam_role.producer_lambda_role.name
  policy_arn = aws_iam_policy.producer_sqs_policy.arn
}

resource "aws_iam_role" "consumer_lambda_role" {
  name = "consumer_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "consumer_lambda_basic" {
  role       = aws_iam_role.consumer_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "consumer_sqs_policy" {
  name        = "consumer_sqs_policy"
  description = "Allow receiving messages from SQS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Effect   = "Allow"
        Resource = aws_sqs_queue.book_queue.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "consumer_sqs_attach" {
  role       = aws_iam_role.consumer_lambda_role.name
  policy_arn = aws_iam_policy.consumer_sqs_policy.arn
}

resource "aws_iam_policy" "consumer_dynamodb_policy" {
  name        = "consumer_dynamodb_policy"
  description = "Allow writing to DynamoDB"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:PutItem"
        ]
        Effect   = "Allow"
        Resource = aws_dynamodb_table.book_table.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "consumer_dynamodb_attach" {
  role       = aws_iam_role.consumer_lambda_role.name
  policy_arn = aws_iam_policy.consumer_dynamodb_policy.arn
}
