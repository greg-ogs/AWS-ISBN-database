resource "aws_api_gateway_rest_api" "book_api" {
  name        = var.api_name
  description = "API for requesting books"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "book_resource" {
  rest_api_id = aws_api_gateway_rest_api.book_api.id
  parent_id   = aws_api_gateway_rest_api.book_api.root_resource_id
  path_part   = "books"
}

resource "aws_api_gateway_method" "post_book" {
  rest_api_id      = aws_api_gateway_rest_api.book_api.id
  resource_id      = aws_api_gateway_resource.book_resource.id
  http_method      = "POST"
  authorization    = "NONE"
  api_key_required = true
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.book_api.id
  resource_id             = aws_api_gateway_resource.book_resource.id
  http_method             = aws_api_gateway_method.post_book.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.producer_lambda.invoke_arn
}

resource "aws_lambda_permission" "api_gateway_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.producer_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.book_api.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on = [aws_api_gateway_integration.lambda_integration]
  rest_api_id = aws_api_gateway_rest_api.book_api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.book_resource.id,
      aws_api_gateway_method.post_book.id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.book_api.id
  stage_name    = "prod"
}

resource "aws_api_gateway_api_key" "book_app_api_key" {
  name = "${var.api_name}-key"
}

resource "aws_api_gateway_usage_plan" "book_app_usage_plan" {
  name = "${var.api_name}-usage-plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.book_api.id
    stage  = aws_api_gateway_stage.prod.stage_name
  }

  quota_settings {
    limit  = 100
    period = "DAY"
  }
}

resource "aws_api_gateway_usage_plan_key" "book_app_usage_plan_key" {
  key_id        = aws_api_gateway_api_key.book_app_api_key.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.book_app_usage_plan.id
}

resource "aws_wafv2_web_acl" "api_waf" {
  name        = "${var.api_name}-waf"
  description = "Rate limiting for API Gateway by IP"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "IPRateLimit"
    priority = 1

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 10
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "Book-app-blocked-by-IPRateLimit"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "Book-app-unblocked-trafic-by-IPRateLimit"
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_web_acl_association" "api_waf_assoc" {
  resource_arn = aws_api_gateway_stage.prod.arn
  web_acl_arn  = aws_wafv2_web_acl.api_waf.arn
}

resource "aws_ssm_parameter" "api_key" {
  name        = "/book-app/${var.api_name}/api-key"
  description = "API Key for ${var.api_name}"
  type        = "SecureString"
  value       = aws_api_gateway_api_key.book_app_api_key.value

  tags = {
    Environment = "prod"
    Application = var.api_name
  }
}
