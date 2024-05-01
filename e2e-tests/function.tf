resource "aws_lambda_function" "jokester" {
  function_name    = "${local.application}${var.resource_suffix}"
  filename         = data.archive_file.jokester_code.output_path
  runtime          = "nodejs20.x"
  handler          = "index.handler"
  source_code_hash = data.archive_file.jokester_code.output_base64sha256
  role             = aws_iam_role.lambda_exec.arn

  environment {
    variables = {
      JOKE_TABLE_SUFFIX = var.resource_suffix
    }
  }

  tags = {
    Application = local.application
    Environment = var.environment
  }
}

data "archive_file" "jokester_code" {
  type        = "zip"
  source_dir  = "${path.module}/../unit-tests"
  output_path = "/tmp/${local.application}-code${var.resource_suffix}.zip"
}

resource "aws_cloudwatch_log_group" "jokester" {
  name              = "/aws/lambda/${aws_lambda_function.jokester.function_name}"
  retention_in_days = 30

  tags = {
    Application = local.application
    Environment = var.environment
  }
}

resource "aws_iam_role" "lambda_exec" {
  name = "${local.application}-exec${var.resource_suffix}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = {
    Application = local.application
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "read_jokes_db_table" {
  name   = "${local.application}-jokes${var.resource_suffix}"
  policy = data.aws_iam_policy_document.access_jokes_table.json
}

data "aws_iam_policy_document" "access_jokes_table" {
  statement {
    actions = [
      "dynamodb:Scan",
      "dynamodb:Query",
      "dynamodb:BatchGetItem",
      "dynamodb:GetItem",
    ]
    resources = [aws_dynamodb_table.jokes.arn]
  }
}

resource "aws_iam_role_policy_attachment" "dynamodb_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.read_jokes_db_table.arn
}
