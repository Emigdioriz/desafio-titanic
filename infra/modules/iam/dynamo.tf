resource "aws_dynamodb_table" "survivals_table" {
  name           = "Survivals_table"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "user_id"

  attribute {
    name = "user_id"
    type = "S"
  }

  tags = {
    Name = "Survivals_table"
  }
}