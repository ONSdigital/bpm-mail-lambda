data "aws_caller_identity" "current" {}

locals {
  prefix             = "${var.app}-${var.stage}"
  attachments_bucket = "${terraform.workspace}-attachments.${var.domain}"
  emails_bucket      = "${terraform.workspace}-emails.${var.domain}"
}
