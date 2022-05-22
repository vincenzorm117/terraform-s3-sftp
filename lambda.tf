
########################################################
# Lambda Permissions


resource "aws_lambda_permission" "apigw" {
  statement_id = "AllowAPIGatewayInvoke"
  action       = "lambda:InvokeFunction"

  function_name = aws_lambda_function.identity-provider.function_name
  principal     = "apigateway.amazonaws.com"

  # The /*/* portion grants access from any method on any resource
  # within the API Gateway "REST API".
  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*"

  depends_on = [
    aws_api_gateway_rest_api.api,
    aws_lambda_function.identity-provider,
  ]
}


resource "aws_iam_role" "identity-provider" {
  name               = "identity-provider"
  assume_role_policy = data.aws_iam_policy_document.identity-provider.json
}

data "aws_iam_policy_document" "identity-provider" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    effect = "Allow"
  }
}


resource "aws_iam_policy" "identity-provider-policy" {
  name        = "test-policy"
  description = "A test policy"

  policy = data.aws_iam_policy_document.identity-provider-policy.json
}

data "aws_iam_policy_document" "identity-provider-policy" {
    statement {
        effect = "Allow"
        actions = ["secretsmanager:GetSecretValue"]
        resources = [
            "arn:aws:secretsmanager:${var.aws_region}:${var.aws_account_id}:secret:SFTP/*"
        ]
    }

    statement {
      effect = "Allow"
      actions = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
      ]
      resources = ["*"]
    }
}

resource "aws_iam_role_policy_attachment" "identity-provider" {
  role       = aws_iam_role.identity-provider.name
  policy_arn = aws_iam_policy.identity-provider-policy.arn
}

########################################################
# Lambda

data "archive_file" "identity-provider" {
  type        = "zip"
  source_dir  = "./lambdas/identity-provider"
  output_path = "./lambdas/identity-provider.zip"
}


resource "aws_lambda_function" "identity-provider" {
  function_name = "shy-moon-5896--identity-provider"
  description   = "Authenticates for the SFTP server."
  role          = aws_iam_role.identity-provider.arn
  handler       = "index.lambda_handler"

  filename         = "./lambdas/identity-provider.zip"
  source_code_hash = data.archive_file.identity-provider.output_base64sha256

  runtime = "python3.7"
  publish = true

  environment {
    variables = {
        SecretsManagerRegion = var.aws_region
    }
  }
}


