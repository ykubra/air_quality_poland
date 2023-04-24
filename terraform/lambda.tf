# TODO: archive files inside terraform
/*data "archive_file" "lambda" {
  type        = "zip"
  source_dir = "../test-lambda/package"
  source_file = "../test-lambda/test-lambda-func."
  output_path = "lambda_function_payload.zip"
}*/

resource "aws_lambda_function" "test_lambda" {
  filename      = "../test-lambda/lambda_function3.zip"
  #filename      = "lambda_function_payload.zip"
  function_name = "lambda_function_name"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "test-lambda-func.lambda_handler"

  #source_code_hash = data.archive_file.lambda.output_base64sha256

  runtime = "python3.9"
  vpc_config {
    subnet_ids         = [aws_subnet.PrivateSubnet.id]
    security_group_ids = [aws_security_group.sg_lambda.id]
  }

}
