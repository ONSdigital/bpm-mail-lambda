resource "aws_iam_user" "nifi" {
  name = "${local.prefix}-nifi"
}

resource "aws_iam_access_key" "nifi" {
  user = aws_iam_user.nifi.name
}

resource "aws_iam_user_policy" "nifi" {
  name = "bpm_nifi_store_email"
  user = aws_iam_user.nifi.name

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

output "nifi_user" {
  value = aws_iam_user.nifi.name
}

output "nifi_key" {
  value = aws_iam_access_key.nifi.secret
}