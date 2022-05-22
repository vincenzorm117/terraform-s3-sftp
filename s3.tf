
resource "aws_s3_bucket" "bucket" {
  bucket = "shy-moon-5896"

  tags = {
    Name        = "my-sftp"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_acl" "bucket" {
  bucket = aws_s3_bucket.bucket.id
  acl    = "private"
}