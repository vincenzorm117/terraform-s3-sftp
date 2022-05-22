terraform {
  backend "s3" {
    bucket               = "jumper-terraform-state"
    key                  = "terraform-sftp-s3/terraform.tfstate"
    region               = "us-east-1"
    encrypt              = true
  }
}
