output "api_endpoint" {
  description = "The invoke URL for the API Gateway endpoint"
  value       = "${aws_api_gateway_stage.prod.invoke_url}/${aws_api_gateway_resource.book_resource.path_part}"
}

output "api_key_ssm_parameter_name" {
  description = "The SSM Parameter name where the API key is stored"
  value       = aws_ssm_parameter.api_key.name
}
