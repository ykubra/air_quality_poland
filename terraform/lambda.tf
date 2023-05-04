
# create an archive to zip necessary libraries 
data "archive_file" "lambda_dependencies_archive" {
  type        = "zip"
  # Unzipped files have follow this structure:
  # python/lib/python3.9/site-packages/{libraries}
  source_dir = "../lambda/packages"
  output_path = "lambda_dependencies_archive.zip"
}
resource "aws_lambda_layer_version" "lambda_dependencies_layer" {
  filename   = "lambda_dependencies_archive.zip"
  layer_name = "lambda_dependencies_layer"
  compatible_runtimes = ["python3.9"]
  compatible_architectures = ["x86_64"]

  source_code_hash = data.archive_file.lambda_dependencies_archive.output_base64sha256
}

# Archive for lambda_data_load
data "archive_file" "lambda_data_load_archive" {
  type        = "zip"
  source_file = "../lambda/data_load_operation.py"
  output_path = "lambda_data_load_archive.zip"
}
# Fetch data with API and transform and upload to RDS
resource "aws_lambda_function" "lambda_data_load" {
  filename      = "lambda_data_load_archive.zip"
  function_name = "data_load_func"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "data_load_operation.lambda_handler"
  layers        = [aws_lambda_layer_version.lambda_dependencies_layer.id]

  source_code_hash = data.archive_file.lambda_data_load_archive.output_base64sha256

  runtime = "python3.9"
  vpc_config {
    subnet_ids         = [aws_subnet.PrivateSubnet.id]
    security_group_ids = [aws_security_group.sg_lambda.id]
  }

}

# Archive for lambda_get_all_data
data "archive_file" "lambda_get_all_data_archive" {
  type        = "zip"
  source_file = "../lambda/get_all_data_operation.py"
  output_path = "lambda_get_all_data_archive.zip"
}
# Returns all data from RDS through API Gateway
resource "aws_lambda_function" "lambda_get_all_data" {
  filename      = "lambda_get_all_data_archive.zip"
  function_name = "get_all_data_func"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "get_all_data_operation.lambda_handler"
  layers        = [aws_lambda_layer_version.lambda_dependencies_layer.id]

  source_code_hash = data.archive_file.lambda_get_all_data_archive.output_base64sha256

  runtime = "python3.9"
  vpc_config {
    subnet_ids         = [aws_subnet.PrivateSubnet.id]
    security_group_ids = [aws_security_group.sg_lambda.id]
  }

}
# permissions for API Gateway to invoke lambda
resource "aws_lambda_permission" "lambda_data_load_permission" {
  statement_id  = "AllowAPIInvokeLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_data_load.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api_gateway.execution_arn}/*"
}
resource "aws_lambda_permission" "lambda_get_all_data_permission" {
  statement_id  = "AllowAPIInvokeLambda"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_get_all_data.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api_gateway.execution_arn}/*"
}