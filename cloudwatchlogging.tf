
resource "aws_iam_role" "CloudWatchLogging" {
  name               = "CloudWatchLoggingRole"
  assume_role_policy = data.aws_iam_policy_document.CloudWatchLogging.json
}

data "aws_iam_policy_document" "CloudWatchLogging" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["transfer.amazonaws.com"]
    }
    effect = "Allow"
  }
}



resource "aws_iam_role_policy_attachment" "CloudWatchLogging" {
  role       = aws_iam_role.CloudWatchLogging.name
  policy_arn = aws_iam_policy.CloudWatchLoggingPolicy.arn
}


resource "aws_iam_policy" "CloudWatchLoggingPolicy" {
  name        = "CloudWatchLoggingPolicy"
  description = "A test policy"

  policy = data.aws_iam_policy_document.CloudWatchLoggingPolicy.json
}

data "aws_iam_policy_document" "CloudWatchLoggingPolicy" {
    statement {
        effect = "Allow"
        actions = [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:DescribeLogStreams",
            "logs:PutLogEvents",
        ]
        resources = [
            "*"
        ]
    }
}