provider "aws" {
  region = "us-east-2"
}

module "iam" {
  source = "./modules/iam"
}

module "lambda" {
  source = "./modules/lambda"
  lambda_role_arn = module.iam.lambda_role_arn
  image_uri       = local.image_uri
  aws_region          = var.aws_region
}

module "api_gateway" {
  source = "./modules/api_gateway"
  lambda_function_arn = module.lambda.lambda_function_arn
  aws_region          = var.aws_region
}