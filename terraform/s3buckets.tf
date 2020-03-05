resource "aws_s3_bucket" "emails" {
    bucket = local.emails_bucket
    policy = <<-POLICY
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "AllowEmailLambda",
                "Effect": "Allow",
                "Principal": {
                    "Service": "lambda.amazonaws.com"
                },
                "Action": "s3:GetObject",
                "Resource": "arn:aws:s3:::${local.emails_bucket}/*",
                "Condition": {
                    "StringEquals": {
                        "aws:SourceArn": "${aws_lambda_function.email.arn}"
                    }
                }
            }
        ]
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
            },
            {
                "Sid": "AllowEmailLambda",
                "Effect": "Allow",
                "Principal": {
                    "Service": "lambda.amazonaws.com"
                },
                "Action": "s3:PutObject",
                "Resource": "arn:aws:s3:::${local.emails_bucket}/*",
                "Condition": {
                    "StringEquals": {
                        "aws:SourceArn": "${aws_lambda_function.email.arn}"
                    }
                }
            },
            {
                "Sid": "AllowEmailLambda",
                "Effect": "Allow",
                "Principal": {
                    "Service": "lambda.amazonaws.com"
                },
                "Action": "s3:GetBucketLocation",
                "Resource": "arn:aws:s3:::${local.emails_bucket}",
                "Condition": {
                    "StringEquals": {
                        "aws:SourceArn": "${aws_lambda_function.email.arn}"
                    }
                }
            }
        ]
    }
POLICY
}
