resource "aws_lambda_function" "api_test" {
  function_name = "titanic_lambda"
  role          = var.lambda_role_arn
  package_type  = "Image"
  image_uri     = var.image_uri
}