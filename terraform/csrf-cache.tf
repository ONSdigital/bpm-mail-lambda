resource "aws_dynamodb_table" "CSRFTokenCache" {
  name         = "${terraform.workspace}-csrf-cache"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "user"

  point_in_time_recovery {
    enabled = false
  }

  attribute {
    name = "user"
    type = "S"
  }

  ttl {
    attribute_name = "expires"
    enabled        = true
  }

  tags = {
    Environment = terraform.workspace
    Name        = "CSRFTokenCache"
  }
}