# Storing out state with s3 bucket

terraform {
    backend "s3" {
        bucket = "my-ts-bucket-practice"
        key = "bucket-key"
        region = "us-east-1"
    }
}
