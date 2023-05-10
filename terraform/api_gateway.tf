# Create API gateway
resource "aws_api_gateway_rest_api" "api_gateway" {
  name = "energy_consumption_api"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# Create API gateway resources for Lambda functions
resource "aws_api_gateway_resource" "data_load_resource" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  parent_id   = aws_api_gateway_rest_api.api_gateway.root_resource_id 
  path_part   = "data_load"
}
resource "aws_api_gateway_resource" "get_all_data_resource" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  parent_id   = aws_api_gateway_rest_api.api_gateway.root_resource_id
  path_part   = "get_all_data"
}

# Create methods for Lambda functions
resource "aws_api_gateway_method" "data_load_method" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.data_load_resource.id
  http_method   = "POST"
  authorization = "NONE"
}
resource "aws_api_gateway_method" "get_all_data_method" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.get_all_data_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

# Integrate endpoints
resource "aws_api_gateway_integration" "data_load_method_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api_gateway.id
  resource_id             = aws_api_gateway_resource.data_load_resource.id
  http_method             = aws_api_gateway_method.data_load_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_data_load.invoke_arn
}
resource "aws_api_gateway_integration" "get_all_data_method_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api_gateway.id
  resource_id             = aws_api_gateway_resource.get_all_data_resource.id
  http_method             = aws_api_gateway_method.get_all_data_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda_get_all_data.invoke_arn
}

# Deploy API gateway
resource "aws_api_gateway_deployment" "api_deployement" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  # Whenever provided resources change that trigers deployement 
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.data_load_resource.id,
      aws_api_gateway_resource.get_all_data_resource.id,
      aws_api_gateway_method.data_load_method.id,
      aws_api_gateway_method.get_all_data_method.id,
      aws_api_gateway_integration.data_load_method_integration.id,
      aws_api_gateway_integration.get_all_data_method_integration.id
    ]))
  }

  depends_on = [
    aws_api_gateway_resource.data_load_resource,
    aws_api_gateway_resource.get_all_data_resource,
    aws_api_gateway_method.data_load_method,
    aws_api_gateway_method.get_all_data_method,
    aws_api_gateway_integration.data_load_method_integration,
    aws_api_gateway_integration.get_all_data_method_integration
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# Create API gateway stage
resource "aws_api_gateway_stage" "api_gateway_stage_production" {
  deployment_id = aws_api_gateway_deployment.api_deployement.id
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  stage_name    = "production"
}
