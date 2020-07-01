data "aws_caller_identity" "current" {}

locals  {
    prefix = "${var.app}-${var.stage}"
    attachments_bucket = "${terraform.workspace}-${var.app}-${var.stage}-attachments.${var.domain}"
    emails_bucket = "${terraform.workspace}-${var.app}-${var.stage}-emails.${var.domain}"
}
