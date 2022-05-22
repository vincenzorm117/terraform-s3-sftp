########################################################
# API Gateway

resource "aws_api_gateway_rest_api" "api" {
  name = "shy-moon-5896"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "servers" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "servers"
}

resource "aws_api_gateway_resource" "serverId" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.servers.id
  path_part   = "{serverId}"
}

resource "aws_api_gateway_resource" "users" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.serverId.id
  path_part   = "users"
}

resource "aws_api_gateway_resource" "username" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.users.id
  path_part   = "{username}"
}

resource "aws_api_gateway_resource" "config" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_resource.username.id
  path_part   = "config"
}



resource "aws_api_gateway_method" "config" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.config.id
  http_method   = "GET"
  authorization = "AWS_IAM"
  request_parameters = {
    "method.request.header.Password" = false
    "method.request.querystring.protocol" = false
    "method.request.querystring.sourceIp" = false
  }
}

resource "aws_api_gateway_method_response" "config" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.config.id
  http_method   = aws_api_gateway_method.config.http_method
  status_code = "200"
  response_models = {
      "application/json" = aws_api_gateway_model.config.name
  }
}

resource "aws_api_gateway_model" "config" {
  rest_api_id  = aws_api_gateway_rest_api.api.id
  name         = "user"
  description  = "a JSON schema"
  content_type = "application/json"

  schema = <<EOF
    {
        "$schema": "http://json-schema.org/draft-04/schema#",
        "title": "UserUserConfig",
        "type": "object",
        "properties": {
            "Role": { "type": "string" },
            "Policy": { "type": "string" },
            "HomeDirectory": { "type": "string" },
            "PublicKeys": { "type": "array", "items": { "type": "string" } }
        }
    }
EOF
}

resource "aws_api_gateway_integration" "config" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.config.id
  http_method             = aws_api_gateway_method.config.http_method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = aws_lambda_function.identity-provider.invoke_arn
  request_templates       = {
    "application/json" = <<-EOT
          {
            "username": "$util.urlDecode($input.params('username'))",
            "password": "$util.escapeJavaScript($input.params('Password')).replaceAll("\\'","'")",
            "protocol": "$input.params('protocol')",
            "serverId": "$input.params('serverId')",
            "sourceIp": "$input.params('sourceIp')"
          }
      EOT
  }
}

resource "aws_api_gateway_integration_response" "config" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.config.id
  http_method = aws_api_gateway_method.config.http_method
  status_code = 200
}


resource "aws_api_gateway_deployment" "api" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_api_gateway_method.config
  ]
}

resource "aws_api_gateway_stage" "api" {
  deployment_id = aws_api_gateway_deployment.api.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "prod"
}


resource "aws_api_gateway_method_settings" "api" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = aws_api_gateway_stage.api.stage_name
  method_path = "*/*"

  settings {
    data_trace_enabled = false
    metrics_enabled = true
    logging_level   = "INFO"
  }
}


########################################################
# API Gateway Cloudwatch logging

resource "aws_api_gateway_account" "apigtw-cw" {
  cloudwatch_role_arn = aws_iam_role.apigtw-cw.arn
  depends_on = [aws_api_gateway_rest_api.api]
}


resource "aws_iam_role" "apigtw-cw" {
  name               = "apigtw-cw"
  assume_role_policy = data.aws_iam_policy_document.apigtw-cw.json
}

data "aws_iam_policy_document" "apigtw-cw" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
    effect = "Allow"
  }
}



resource "aws_iam_role_policy_attachment" "apigtw-cw-policy" {
  role       = aws_iam_role.apigtw-cw.name
  policy_arn = aws_iam_policy.apigtw-cw-policy.arn
}


resource "aws_iam_policy" "apigtw-cw-policy" {
  name        = "apigtw-cw-policy"
  description = "apigtw-cw-policy"

  policy = data.aws_iam_policy_document.apigtw-cw-policy.json
}

data "aws_iam_policy_document" "apigtw-cw-policy" {
    statement {
        effect = "Allow"
        actions = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:DescribeLogGroups",
            "logs:DescribeLogStreams",
            "logs:PutLogEvents",
            "logs:GetLogEvents",
            "logs:FilterLogEvents",
        ]
        resources = [
            "*"
        ]
    }
}