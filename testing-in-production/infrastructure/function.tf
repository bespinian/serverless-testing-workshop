resource "aws_lambda_function" "my_function" {
  function_name    = "${local.application}${var.resource_suffix}"
  filename         = data.archive_file.my_function.output_path
  runtime          = "nodejs18.x"
  handler          = "index.handler"
  source_code_hash = data.archive_file.my_function.output_base64sha256
  role             = aws_iam_role.lambda_exec.arn
  publish          = true

  environment {
    variables = {
      JOKE_TABLE_SUFFIX = "${var.resource_suffix}"
    }
  }

  tags = {
    Application = local.application
  }
}

resource "aws_lambda_alias" "production" {
  name             = "production"
  function_name    = aws_lambda_function.my_function.function_name
  function_version = "1"
}

data "archive_file" "my_function" {
  type        = "zip"
  source_dir  = "${path.module}/../function"
  output_path = "/tmp/${local.application}-code${var.resource_suffix}.zip"
}

resource "aws_cloudwatch_log_group" "my_function" {
  name              = "/aws/lambda/${aws_lambda_function.my_function.function_name}"
  retention_in_days = 30

  tags = {
    Application = local.application
  }
}

resource "aws_iam_role" "lambda_exec" {
  name = "${local.application}-exec${var.resource_suffix}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = {
    Application = local.application
  }
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
