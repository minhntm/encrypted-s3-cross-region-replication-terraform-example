locals {
  email_receiving_rule_set_name = "${var.prefix}-email-receiving-rule-set"
  email_receiving_rule_name     = "${var.prefix}-save-to-s3"
}

resource "aws_ses_receipt_rule_set" "main_rule_set" {
  provider      = aws.us-east-1
  rule_set_name = local.email_receiving_rule_set_name
}

resource "aws_ses_active_receipt_rule_set" "active_main_rule_set" {
  provider      = aws.us-east-1
  rule_set_name = local.email_receiving_rule_set_name
  depends_on = [
    aws_ses_receipt_rule_set.main_rule_set
  ]
}

resource "aws_ses_receipt_rule" "save_to_s3_rule" {
  provider      = aws.us-east-1
  name          = local.email_receiving_rule_name
  rule_set_name = local.email_receiving_rule_set_name
  recipients    = ["xxx@jaas.link"]
  enabled       = true
  scan_enabled  = true
  tls_policy    = "Require"

  s3_action {
    bucket_name = var.source_bucket_name
    kms_key_arn = aws_kms_key.source_bucket_cmk.arn
    position    = 1
  }

  depends_on = [
    aws_ses_receipt_rule_set.main_rule_set,
    aws_s3_bucket.source_bucket
  ]
}
