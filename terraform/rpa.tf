resource "aws_iam_user" "rpa" {
  name = "${local.prefix}-rpa"
}

resource "aws_iam_access_key" "rpa" {
  user = aws_iam_user.rpa.name
}

resource "aws_iam_user_policy" "rpa" {
  name = "bpm_rpa_store_email"
  user = aws_iam_user.rpa.name

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:PutObject"
      ],
      "Effect": "Allow",
      "Resource": [
          "arn:aws:s3:::${local.emails_bucket}/*",
          "arn:aws:s3:::${local.attachments_bucket}/*"
          ]
    }
  ]
}
EOF
}

output "rpa_user" {
  value = aws_iam_user.rpa.name
}

output "rpa_key" {
  value = aws_iam_access_key.rpa.id
}

output "rpa_secret_key" {
  value = aws_iam_access_key.rpa.secret
}
