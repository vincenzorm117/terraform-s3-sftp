
variable "project" {
  type        = string
  description = "Name of project"
}

variable "aws_account_id" {
  type        = string
  description = "AWS account id"
}

variable "aws_access_key" {
  type        = string
  description = "AWS programmatic access key"
}

variable "aws_secret_key" {
  type        = string
  description = "AWS programmatic secret key"
}

variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "dns_zone_id" {
  type        = string
  description = "Zone id for domain"
}


