provider "aws" {
  region = "us-east-2"
}

variable "region" {
  description = "The AWS region to deploy the API Gateway"
  type        = string
  default     = "us-east-2"
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_basic_execution_v2"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "ecr_access" {
  name = "ECRAccessPolicy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = [
          "dynamodb:Scan",
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
        ]
        Resource = aws_dynamodb_table.survivals_table.arn
      }
    ]
  })
}

resource "aws_lambda_function" "api_test" {
  function_name = "api_test_function_v2"
  role          = aws_iam_role.lambda_role.arn
  package_type  = "Image"
  image_uri     = "021891592095.dkr.ecr.us-east-2.amazonaws.com/desafio:teste_v6"
}

resource "aws_api_gateway_rest_api" "api" {
  name        = "desafio"
  description = "API para teste v2"
}

resource "aws_api_gateway_resource" "teste_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "teste"
}

resource "aws_api_gateway_method" "get_teste" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.teste_resource.id
  http_method   = "GET"
  authorization = "NONE"
  request_parameters = {
    "method.request.querystring.user_id" = true
  }
}

resource "aws_api_gateway_method" "post_teste" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.teste_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "delete_teste" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.teste_resource.id
  http_method   = "DELETE"
  authorization = "NONE"
  request_parameters = {
    "method.request.querystring.user_id" = true
  }
}

resource "aws_api_gateway_integration" "get_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.teste_resource.id
  http_method             = aws_api_gateway_method.get_teste.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api_test.invoke_arn

  request_parameters = {
  "integration.request.querystring.user_id" = "method.request.querystring.user_id"
  }
}

resource "aws_api_gateway_integration" "post_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.teste_resource.id
  http_method             = aws_api_gateway_method.post_teste.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api_test.invoke_arn
}

resource "aws_api_gateway_integration" "delete_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.teste_resource.id
  http_method             = aws_api_gateway_method.delete_teste.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.api_test.invoke_arn

  request_parameters = {
    "integration.request.querystring.user_id" = "method.request.querystring.user_id"
  }
}

resource "aws_lambda_permission" "get_api_gateway" {
  statement_id  = "AllowGetAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_test.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/GET/teste"
}

resource "aws_lambda_permission" "post_api_gateway" {
  statement_id  = "AllowPostAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_test.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/POST/teste"
}

resource "aws_lambda_permission" "delete_api_gateway" {
  statement_id  = "AllowDeleteAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.api_test.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/DELETE/teste"
}

resource "aws_api_gateway_deployment" "api_deployment" {
  depends_on = [
    aws_api_gateway_method.get_teste,
    aws_api_gateway_method.post_teste,
    aws_api_gateway_method.delete_teste,
    aws_api_gateway_integration.post_lambda_integration,
    aws_api_gateway_integration.get_lambda_integration,
    aws_api_gateway_integration.delete_lambda_integration,
    aws_lambda_permission.post_api_gateway,
    aws_lambda_permission.get_api_gateway,
    aws_lambda_permission.delete_api_gateway
  ]
  rest_api_id = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.api_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "prod"
}

output "api_url" {
  value = "https://${aws_api_gateway_rest_api.api.id}.execute-api.${var.region}.amazonaws.com/${aws_api_gateway_stage.prod.stage_name}/teste"
}