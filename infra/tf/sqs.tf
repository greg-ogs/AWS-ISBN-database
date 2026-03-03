resource "aws_sqs_queue" "book_dlq" {
  name = var.sqs_dlq_name
}

resource "aws_sqs_queue" "book_queue" {
  name = var.sqs_queue_name

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.book_dlq.arn
    maxReceiveCount     = 3
  })
}
