################################################################
# Transfer Server

resource "aws_transfer_server" "sftp_server" {
  identity_provider_type = "API_GATEWAY"
  logging_role           = aws_iam_role.CloudWatchLogging.arn
  url = aws_api_gateway_stage.api.invoke_url
  invocation_role = aws_iam_role.transferidentity-provider.arn
}

resource "aws_route53_record" "sft-dns-record" {
  zone_id  = var.dns_zone_id
  name     = "sftp.vincenzo.cloud"
  type     = "CNAME"
  ttl      = "600"
  records  = [aws_transfer_server.sftp_server.endpoint]
}

################################################################
# Transfer Server Permissions

resource "aws_iam_role" "transferidentity-provider" {
  name               = "transferidentity-provider"
  assume_role_policy = data.aws_iam_policy_document.transferidentity-provider.json
}



data "aws_iam_policy_document" "transferidentity-provider" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["transfer.amazonaws.com"]
    }
    effect = "Allow"
  }
}



resource "aws_iam_role_policy_attachment" "transferidentity-provider" {
  role       = aws_iam_role.transferidentity-provider.name
  policy_arn = aws_iam_policy.transferidentity-provider-policy.arn
}


resource "aws_iam_policy" "transferidentity-provider-policy" {
  name        = "transferidentity-provider-policy"
  description = "transferidentity-provider-policy"

  policy = data.aws_iam_policy_document.transferidentity-provider-policy.json
}


data "aws_iam_policy_document" "transferidentity-provider-policy" {
  statement {
    sid = "TransferCanInvokeThisApi"
    effect = "Allow"
    actions = ["execute-api:Invoke"]
    resources = [
        "${aws_api_gateway_stage.api.execution_arn}/GET/*"
    ]
  }

  statement {
    sid = "TransferCanReadThisApi"
    effect = "Allow"
    actions = ["apigateway:GET"]
    resources = [
        "*"
    ]
  }
}


################################################################
# User Permissions

resource "aws_iam_role" "sftp_service_role" {
  name               = "sftp-s3-access-role"
  assume_role_policy = data.aws_iam_policy_document.trust_relationship.json
}

data "aws_iam_policy_document" "trust_relationship" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type        = "Service"
      identifiers = ["transfer.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy_attachment" "sftp-user-perms" {
  name       = "sftpUserPermissions-attachment"
  roles      = [aws_iam_role.sftp_service_role.name]
  policy_arn = aws_iam_policy.sftp-user-perms.arn
}

resource "aws_iam_policy" "sftp-user-perms" {
  name        = "sftpUserPermissions"
  description = "SFTP User permissions"

  policy = data.aws_iam_policy_document.sftp-user-perms.json
}

data "aws_iam_policy_document" "sftp-user-perms" {

  statement {
    effect = "Allow"
    sid    = "HomeDirAccess"
    actions = [
        "s3:ListBucket",
        "s3:GetBucketLocation"
    ]
    resources = [aws_s3_bucket.bucket.arn]
  }
  
  statement {
    effect = "Allow"
    sid    = "HomeDirObjectAccess"
    actions = [
        "s3:PutObject",
        "s3:GetObjectAcl",
        "s3:GetObject",
        "s3:DeleteObjectVersion",
        "s3:DeleteObject",
        "s3:PutObjectAcl",
        "s3:GetObjectVersion"
    ]
    resources = [
      "${aws_s3_bucket.bucket.arn}/*",
    ]
  }
}