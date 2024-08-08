variable "aws_region" {
  type = string
}

variable "aws_account_id" {
  type = string
}

variable "repository_name" {
  type = string
}

variable "image_tag" {
  type = string
}

locals {
  image_uri = "${var.aws_account_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${var.repository_name}:${var.image_tag}"
}