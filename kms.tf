resource "aws_kms_key" "source_bucket_cmk" {
  provider            = aws.us-east-1
  is_enabled          = true
  enable_key_rotation = false
  policy              = data.aws_iam_policy_document.source_bucket_cmk_policy.json
}

resource "aws_kms_alias" "source_bucket_cmk" {
  provider      = aws.us-east-1
  name          = "alias/${var.prefix}-source-cmk"
  target_key_id = aws_kms_key.source_bucket_cmk.key_id
}

data "aws_iam_policy_document" "source_bucket_cmk_policy" {
  # Root Access
  statement {
    sid     = "Enable IAM User Permissions"
    effect  = "Allow"
    actions = ["kms:*"]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
      ]
    }
    resources = ["*"]
  }
}

resource "aws_kms_key" "destination_bucket_cmk" {
  count               = var.does_destination_bucket_exist ? 0 : 1
  is_enabled          = true
  enable_key_rotation = false
  policy              = data.aws_iam_policy_document.destination_bucket_cmk_policy[0].json
}

resource "aws_kms_alias" "destination_bucket_cmk" {
  count         = var.does_destination_bucket_exist ? 0 : 1
  name          = "alias/${var.prefix}-destination-cmk"
  target_key_id = aws_kms_key.destination_bucket_cmk[0].key_id
}

data "aws_iam_policy_document" "destination_bucket_cmk_policy" {
  count = var.does_destination_bucket_exist ? 0 : 1
  # Root Access
  statement {
    sid     = "Enable IAM User Permissions"
    effect  = "Allow"
    actions = ["kms:*"]
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
      ]
    }
    resources = ["*"]
  }

}
