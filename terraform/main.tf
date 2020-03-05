provider "aws" {
  region = "eu-west-2"
}

locals  {
    prefix = "${var.app}-${var.stage}"
    attachments_bucket = "${local.prefix}-attachments-in.${var.domain}"
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