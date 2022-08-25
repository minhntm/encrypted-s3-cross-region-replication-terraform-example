# Encrypted S3 Cross Region Replication with Terraform

## How to run

- `cp sample.tfvars terraform.tfvars`
- Update the variables
- If you already had the destination bucket and its kms key:

```
does_destination_bucket_exist = true
destination_bucket_name       = "CURRENT_DESTINATION_BUCKET_NAME"
destination_bucket_key_arn    = "YOUR_KEY_ARN"
```

- If not:

```
destination_bucket_name       = "NEW_DESTINATION_BUCKET_NAME"
does_destination_bucket_exist = false
destination_bucket_key_arn    = ""
```

- Run the code:

```
terraform init
terraform apply
```
