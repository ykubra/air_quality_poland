resource "aws_api_gateway_rest_api" "api_gateway" {
  name = "energy_consumption_api"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

#create resource

resource "aws_api_gateway_resource" "database_resource" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  parent_id   = aws_api_gateway_rest_api.api_gateway.root_resource_id # In this case, the parent id should the gateway root_resource_id.
  path_part   = "database"
}

#create method

resource "aws_api_gateway_method" "get_all_data_method" {
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  resource_id   = aws_api_gateway_resource.database_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

#integrate endpoints

resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.api_gateway.id
  resource_id             = aws_api_gateway_resource.database_resource.id
  http_method             = aws_api_gateway_method.get_all_data_method.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.lambda.invoke_arn
}
/*
resource "aws_api_gateway_method_response" "response_200" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  resource_id = aws_api_gateway_resource.database_resource.id
  http_method = aws_api_gateway_method.get_all_data_method.http_method
  status_code = "200"
}

resource "aws_api_gateway_integration_response" "MyDemoIntegrationResponse" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id
  resource_id = aws_api_gateway_resource.database_resource.id
  http_method = aws_api_gateway_method.get_all_data_method.http_method
  status_code = aws_api_gateway_method_response.response_200.status_code

  # Transforms the backend JSON response to XML
  response_templates = {
    "application/xml" = <<EOF
#set($inputRoot = $input.path('$'))
<?xml version="1.0" encoding="UTF-8"?>
<message>
    $inputRoot.body
</message>
EOF
  }
}*/

resource "aws_api_gateway_deployment" "api_deployement" {
  rest_api_id = aws_api_gateway_rest_api.api_gateway.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.database_resource.id,
      aws_api_gateway_method.get_all_data_method.id,
      aws_api_gateway_integration.integration.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "example" {
  deployment_id = aws_api_gateway_deployment.api_deployement.id
  rest_api_id   = aws_api_gateway_rest_api.api_gateway.id
  stage_name    = "production"
}
