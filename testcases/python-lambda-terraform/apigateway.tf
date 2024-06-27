resource "aws_api_gateway_rest_api" "first_api" {
  name = "brandon-terraform-demo-api-first"
  description = "test app terraform deployment"
}

resource "aws_api_gateway_resource" "first_proxy" {
  rest_api_id = aws_api_gateway_rest_api.first_api.id
  parent_id   = aws_api_gateway_rest_api.first_api.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "first_proxy" {
  rest_api_id   = aws_api_gateway_rest_api.first_api.id
  resource_id   = aws_api_gateway_resource.first_proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "first_lambda" {
  rest_api_id = aws_api_gateway_rest_api.first_api.id
  resource_id = aws_api_gateway_method.first_proxy.resource_id
  http_method = aws_api_gateway_method.first_proxy.http_method

  integration_http_method = "GET"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.brandon_test_lambda_first.invoke_arn
}

 resource "aws_api_gateway_method" "first_proxy_root" {
   rest_api_id   = aws_api_gateway_rest_api.first_api.id
   resource_id   = aws_api_gateway_rest_api.first_api.root_resource_id
   http_method   = "ANY"
   authorization = "NONE"
 }

 resource "aws_api_gateway_integration" "first_lambda_root" {
   rest_api_id = aws_api_gateway_rest_api.first_api.id
   resource_id = aws_api_gateway_method.first_proxy_root.resource_id
   http_method = aws_api_gateway_method.first_proxy_root.http_method

   integration_http_method = "GET"
   type                    = "AWS_PROXY"
   uri                     = aws_lambda_function.brandon_test_lambda_first.invoke_arn
 }

 resource "aws_api_gateway_deployment" "first_deployment" {
   depends_on = [
     aws_api_gateway_integration.first_lambda,
     aws_api_gateway_integration.first_lambda_root,
   ]

   rest_api_id = aws_api_gateway_rest_api.first_api.id
   stage_name  = "test"
 }


# second
resource "aws_api_gateway_rest_api" "second_api" {
  name = "brandon-terraform-demo-api-second"
  description = "test app terraform deployment"
}

resource "aws_api_gateway_resource" "second_proxy" {
  rest_api_id = aws_api_gateway_rest_api.second_api.id
  parent_id   = aws_api_gateway_rest_api.second_api.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "second_proxy" {
  rest_api_id   = aws_api_gateway_rest_api.second_api.id
  resource_id   = aws_api_gateway_resource.second_proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "second_lambda" {
  rest_api_id = aws_api_gateway_rest_api.second_api.id
  resource_id = aws_api_gateway_method.second_proxy.resource_id
  http_method = aws_api_gateway_method.second_proxy.http_method

  integration_http_method = "GET"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.brandon_test_lambda_second.invoke_arn
}

resource "aws_api_gateway_method" "second_proxy_root" {
  rest_api_id   = aws_api_gateway_rest_api.second_api.id
  resource_id   = aws_api_gateway_rest_api.second_api.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "second_lambda_root" {
  rest_api_id = aws_api_gateway_rest_api.second_api.id
  resource_id = aws_api_gateway_method.second_proxy_root.resource_id
  http_method = aws_api_gateway_method.second_proxy_root.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.brandon_test_lambda_second.invoke_arn
}

resource "aws_api_gateway_deployment" "second_deployment" {
  depends_on = [
    aws_api_gateway_integration.second_lambda,
    aws_api_gateway_integration.second_lambda_root,
  ]

  rest_api_id = aws_api_gateway_rest_api.second_api.id
  stage_name  = "test"
}



output "first_base_url" {
   value = aws_api_gateway_deployment.first_deployment.invoke_url
}
output "second_base_url" {
   value = aws_api_gateway_deployment.second_deployment.invoke_url
 }
