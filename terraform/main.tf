provider "aws" {
  region = "eu-west-2"
}

data "aws_caller_identity" "current" {}

locals  {
    prefix = "${var.app}-${var.stage}"
    attachments_bucket = "${local.prefix}-attachments.${var.domain}"
    emails_bucket = "${local.prefix}-emails.${var.domain}"
}

terraform {
  backend "s3" {
    bucket               = "terraform.bpm.ons.digital"
    key                  = "lambdas/mail.tfstate"
    region               = "eu-west-2"
    workspace_key_prefix = "workspaces"
  }
}