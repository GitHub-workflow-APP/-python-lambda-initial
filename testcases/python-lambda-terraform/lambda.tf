provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

provider "archive" {}


resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

data "archive_file" "lambda_arc" {
    type        = "zip"
    output_path = "${path.module}/lambdas.zip"
    source_dir = "${path.module}/src"
}



resource "aws_lambda_function" "brandon_test_lambda_first" {
  depends_on    = [
    data.archive_file.lambda_arc,
    aws_iam_role_policy_attachment.first_lambda_logs, 
    aws_cloudwatch_log_group.first_group
  ]
  filename      = data.archive_file.lambda_arc.output_path
  function_name = "brandon-terraform-demo-first"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "initial.terra_get"

  # The filebase64sha256() function is available in Terraform 0.11.12 and later
  # For Terraform 0.11.11 and earlier, use the base64sha256() function and the file() function:
  # source_code_hash = "${base64sha256(file("lambda_function_payload.zip"))}"
  #source_code_hash = "${filebase64sha256("lambda_function_payload.zip")}"

  runtime = "python3.7"


}

resource "aws_lambda_function" "brandon_test_lambda_second" {
  depends_on    = [
    data.archive_file.lambda_arc,
    aws_iam_role_policy_attachment.second_lambda_logs, 
    aws_cloudwatch_log_group.second_group
  ]
  filename      = data.archive_file.lambda_arc.output_path
  function_name = "brandon-terraform-demo-second"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "initial.terra_post"

  runtime = "python3.7"

}

resource "aws_lambda_permission" "first_apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.brandon_test_lambda_first.function_name
  principal     = "apigateway.amazonaws.com"

  # The "/*/*" portion grants access from any method on any resource
  # within the API Gateway REST API.
  source_arn = "${aws_api_gateway_rest_api.first_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "second_apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.brandon_test_lambda_second.function_name
  principal     = "apigateway.amazonaws.com"

  # The "/*/*" portion grants access from any method on any resource
  # within the API Gateway REST API.
  source_arn = "${aws_api_gateway_rest_api.second_api.execution_arn}/*/*"
}

resource "aws_cloudwatch_log_group" "first_group" {
  name              = "/aws/lambda/brandon-terraform-demo-first"
  retention_in_days = 14
}

# See also the following AWS managed policy: AWSLambdaBasicExecutionRole
resource "aws_iam_policy" "first_iam_policy" {
  name = "brandon-terraform-lambda-first"
  path = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource": "arn:aws:logs:*:*:*",
        "Effect": "Allow"
      }
    ]
  }
  EOF
}

resource "aws_iam_role_policy_attachment" "first_lambda_logs" {
  role = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.first_iam_policy.arn
}
resource "aws_cloudwatch_log_group" "second_group" {
  name              = "/aws/lambda/brandon-terraform-demo-second"
  retention_in_days = 14
}

# See also the following AWS managed policy: AWSLambdaBasicExecutionRole
resource "aws_iam_policy" "second_iam_policy" {
  name = "brandon-terraform-lambda-second"
  path = "/"
  description = "IAM policy for logging from a lambda"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        "Resource": "arn:aws:logs:*:*:*",
        "Effect": "Allow"
      }
    ]
  }
  EOF
}

resource "aws_iam_role_policy_attachment" "second_lambda_logs" {
  role = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.second_iam_policy.arn
}
