resource "aws_s3_bucket" "source_bucket" {
  provider = aws.us-east-1
  bucket   = var.source_bucket_name
  // TODO: change to false
  force_destroy = true

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = aws_kms_key.source_bucket_cmk.arn
      }
      # https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucket-key.html
      bucket_key_enabled = true
    }
  }

}

data "aws_iam_policy_document" "source_bucket_policy" {
  statement {
    sid    = "AllowSESPuts"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ses.amazonaws.com"]
    }
    actions = [
      "s3:PutObject"
    ]
    resources = [
      "arn:aws:s3:::${var.source_bucket_name}/*",
    ]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_s3_bucket_policy" "source_bucket" {
  provider = aws.us-east-1
  bucket   = aws_s3_bucket.source_bucket.id
  policy   = data.aws_iam_policy_document.source_bucket_policy.json
}

resource "aws_s3_bucket_public_access_block" "source_bucket" {
  provider                = aws.us-east-1
  bucket                  = aws_s3_bucket.source_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "destination_bucket" {
  count  = var.does_destination_bucket_exist == true ? 0 : 1
  bucket = var.destination_bucket_name
  // TODO: change to false
  force_destroy = true

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = aws_kms_key.destination_bucket_cmk[0].arn
      }
      # https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucket-key.html
      bucket_key_enabled = true
    }
  }
}

resource "aws_s3_bucket_public_access_block" "destination_bucket" {
  count                   = var.does_destination_bucket_exist == true ? 0 : 1
  bucket                  = aws_s3_bucket.destination_bucket[0].id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_replication_configuration" "encrypted_s3_cross_region_replication" {
  provider   = aws.us-east-1
  depends_on = [aws_s3_bucket.source_bucket]

  role   = aws_iam_role.encrypted_s3_replication_role.arn
  bucket = aws_s3_bucket.source_bucket.id

  rule {
    id = "encrypted-s3-cross-region-replication"

    status = "Enabled"

    destination {
      bucket = "arn:aws:s3:::${var.destination_bucket_name}"
      encryption_configuration {
        replica_kms_key_id = var.does_destination_bucket_exist ? var.destination_bucket_key_arn : aws_kms_key.destination_bucket_cmk[0].arn
      }
    }

    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }
  }
}
