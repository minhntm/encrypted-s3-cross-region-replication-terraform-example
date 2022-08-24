locals {
  source_bucket_name      = "${var.prefix}-source"
  destination_bucket_name = "${var.prefix}-destination"
}

resource "aws_s3_bucket" "source_bucket" {
  provider = aws.us-east-1
  bucket   = local.source_bucket_name
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

resource "aws_s3_bucket_public_access_block" "source_bucket" {
  provider                = aws.us-east-1
  bucket                  = aws_s3_bucket.source_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "destination_bucket" {
  bucket = local.destination_bucket_name
  // TODO: change to false
  force_destroy = true

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = aws_kms_key.destination_bucket_cmk.arn
      }
      # https://docs.aws.amazon.com/AmazonS3/latest/userguide/bucket-key.html
      bucket_key_enabled = true
    }
  }
}

resource "aws_s3_bucket_public_access_block" "destination_bucket" {
  bucket                  = aws_s3_bucket.destination_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_replication_configuration" "encrypted_s3_cross_region_replication" {
  provider   = aws.us-east-1
  depends_on = [aws_s3_bucket.source_bucket, aws_s3_bucket.destination_bucket]

  role   = aws_iam_role.encrypted_s3_replication_role.arn
  bucket = aws_s3_bucket.source_bucket.id

  rule {
    id = "encrypted-s3-cross-region-replication"

    status = "Enabled"

    destination {
      bucket = aws_s3_bucket.destination_bucket.arn
      encryption_configuration {
        replica_kms_key_id = aws_kms_key.destination_bucket_cmk.arn
      }
    }

    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }
  }
}
