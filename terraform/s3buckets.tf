resource "aws_s3_bucket" "emails" {
    bucket = local.emails_bucket
    policy = <<-POLICY
    {
        "Version": "2012-10-17",
        "Statement": [%{ if var.stage == "dev" }
            {
                "Sid": "AllowSESPuts",
                "Effect": "Allow",
                "Principal": {
                    "Service": "ses.amazonaws.com"
                },
                "Action": "s3:PutObject",
                "Resource": "arn:aws:s3:::${local.emails_bucket}/*",
                "Condition": {
                    "StringEquals": {
                        "aws:Referer": "${data.aws_caller_identity.current.account_id}"
                    }
                }
            }
        %{ endif }]
    }
POLICY
}

resource "aws_s3_bucket" "attachments" {
    bucket = local.attachments_bucket
    policy = <<-POLICY
    {
        "Version":"2012-10-17",
        "Statement":[
            {
            "Sid":"PublicRead",
            "Effect":"Allow",
            "Principal": "*",
            "Action":["s3:GetObject"],
            "Resource":["arn:aws:s3:::${local.attachments_bucket}/*"]
            }
        ]
    }
POLICY
}

resource "aws_iam_policy" "email-lambda-s3-policy" {
    name        = "${local.prefix}-email-s3-lambda"
    description = "Least privilege permissions for BPM Email ingress lambda"

    policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "s3:GetObject",
            "Resource": "arn:aws:s3:::${local.emails_bucket}/*"
        },
        {
            "Effect": "Allow",
            "Action": "s3:PutObject",
            "Resource": "arn:aws:s3:::${local.attachments_bucket}/*"
        },
        {
            "Effect": "Allow",
            "Action": "s3:GetBucketLocation",
            "Resource": "arn:aws:s3:::${local.attachments_bucket}"
        }
    ]
}
POLICY
}
