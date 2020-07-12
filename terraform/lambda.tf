resource "aws_iam_role" "email_lambda" {
  name               = "${terraform.workspace}-${local.prefix}-lambda"
  assume_role_policy = <<-EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": "lambda.amazonaws.com"
            },
            "Effect": "Allow"
            }
        ]
    }
EOF
}
resource "aws_iam_role_policy_attachment" "add_cloudwatch" {
  role       = aws_iam_role.email_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
resource "aws_iam_role_policy_attachment" "add_s3" {
  role       = aws_iam_role.email_lambda.name
  policy_arn = aws_iam_policy.email-lambda-s3-policy.arn
}
resource "aws_lambda_function" "email" {
  filename      = "../../generated/function.zip"
  runtime       = "python3.8"
  role          = aws_iam_role.email_lambda.arn
  function_name = "${terraform.workspace}-ingest"
  handler       = "lambda_function.lambda_handler"
  description   = "BPM Prices Correspondence new instance email trigger"
  timeout       = 30
  environment {
    variables = {
      ATTACHMENT_BUCKET = local.attachments_bucket
      BPM_CSRF_URL      = "https://ons-bawoc.bpm.ibmcloud.com/baw/${var.stage}/bpm/system/login"
      BPM_EMAIL_URL     = "https://ons-bawoc.bpm.ibmcloud.com/baw/${var.stage}/bpm/processes?model=Prices%20Correspondence&container=PRICOR"
      BPM_USER          = var.BPM_USER
      BPM_PW            = var.BPM_PW
    }
  }
}
resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.email.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.emails.arn
}
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = local.emails_bucket
  lambda_function {
    lambda_function_arn = aws_lambda_function.email.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "manifest/"
  }
}