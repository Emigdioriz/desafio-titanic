resource "aws_api_gateway_rest_api" "api" {
  name        = "titanic_api"
  description = "API para sobreviventes do titanic"
}

resource "aws_api_gateway_resource" "api_gateway_resource_sobreviventes" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "sobreviventes"
}

resource "aws_api_gateway_method" "get_teste" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.api_gateway_resource_sobreviventes.id
  http_method   = "GET"
  authorization = "NONE"
  request_parameters = {
    "method.request.querystring.user_id" = true
  }
}

resource "aws_api_gateway_method" "post_teste" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.api_gateway_resource_sobreviventes.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "delete_teste" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.api_gateway_resource_sobreviventes.id
  http_method   = "DELETE"
  authorization = "NONE"
  request_parameters = {
    "method.request.querystring.user_id" = true
  }
}

resource "aws_api_gateway_integration" "get_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.api_gateway_resource_sobreviventes.id
  http_method             = aws_api_gateway_method.get_teste.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
 uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${var.lambda_function_arn}/invocations"

  request_parameters = {
    "integration.request.querystring.user_id" = "method.request.querystring.user_id"
  }
}

resource "aws_api_gateway_integration" "post_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.api_gateway_resource_sobreviventes.id
  http_method             = aws_api_gateway_method.post_teste.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${var.lambda_function_arn}/invocations"
}

resource "aws_api_gateway_integration" "delete_lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.api_gateway_resource_sobreviventes.id
  http_method             = aws_api_gateway_method.delete_teste.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${var.lambda_function_arn}/invocations"

  request_parameters = {
    "integration.request.querystring.user_id" = "method.request.querystring.user_id"
  }
}

resource "aws_lambda_permission" "get_api_gateway" {
  statement_id  = "AllowGetAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/GET/sobreviventes"
}

resource "aws_lambda_permission" "post_api_gateway" {
  statement_id  = "AllowPostAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/POST/sobreviventes"
}

resource "aws_lambda_permission" "delete_api_gateway" {
  statement_id  = "AllowDeleteAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/DELETE/sobreviventes"
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