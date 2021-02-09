data "aws_caller_identity" "current" {}

locals {
  prefix             = "${var.app}-${var.stage}"
  attachments_bucket = "${terraform.workspace}-${local.prefix}-attachments.${var.domain}"
  emails_bucket      = "${terraform.workspace}-${local.prefix}-emails.${var.domain}"
  BPM_environments = {
    dev     = "dev"
    preprod = "test"
    prod    = "run"
  }
  bpm_env = local.BPM_environments[var.stage]
}
