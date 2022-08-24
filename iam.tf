data "aws_iam_policy_document" "s3_replication_sts_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
    actions = [
      "sts:AssumeRole"
    ]
  }
}

resource "aws_iam_role" "encrypted_s3_replication_role" {
  name               = "encrypted_s3_replication_role"
  assume_role_policy = data.aws_iam_policy_document.s3_replication_sts_policy.json
}

resource "aws_iam_role_policy" "encrypted_s3_replication_role_policy" {
  name   = "encrypted_s3_replication_role_policy"
  role   = aws_iam_role.encrypted_s3_replication_role.id
  policy = data.aws_iam_policy_document.encrypted_s3_replication_role_policy_document.json
}

data "aws_iam_policy_document" "encrypted_s3_replication_role_policy_document" {
  statement {
    effect = "Allow"
    resources = [
      "arn:aws:s3:::${local.source_bucket_name}",
      "arn:aws:s3:::${local.source_bucket_name}/*"
    ]
    actions = [
      "s3:ListBucket",
      "s3:GetReplicationConfiguration",
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateTags",
    ]
    resources = ["arn:aws:s3:::${local.destination_bucket_name}/*"]

    condition {
      test     = "StringLikeIfExists"
      variable = "s3:x-amz-server-side-encryption"
      values = [
        "aws:kms",
        "AES256",
      ]
    }

    condition {
      test     = "StringLikeIfExists"
      variable = "s3:x-amz-server-side-encryption-aws-kms-key-id"
      values   = [aws_kms_key.destination_bucket_cmk.arn]
    }
  }

  statement {
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [aws_kms_key.source_bucket_cmk.arn]

    condition {
      test     = "StringLike"
      variable = "kms:ViaService"
      values   = ["s3.us-east-1.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:s3:arn"
      values   = ["arn:aws:s3:::${local.source_bucket_name}"]
    }
  }

  statement {
    effect    = "Allow"
    actions   = ["kms:Encrypt"]
    resources = [aws_kms_key.destination_bucket_cmk.arn]

    condition {
      test     = "StringLike"
      variable = "kms:ViaService"
      values   = ["s3.ap-northeast-1.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "kms:EncryptionContext:aws:s3:arn"
      values   = ["arn:aws:s3:::${local.destination_bucket_name}"]
    }
  }
}
