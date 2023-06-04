variable "admin_email_address" {
  default = "cuyu9779@gmail.com"
}

#lambda에 권한 생성
resource "aws_iam_role_policy" "cal-and-send-cur" {
  name   = "cal-and-send-cur"
  role = aws_iam_role.cal-and-send-cur-role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "athena:*",
          "sns:Publish",
          "sns:GetTopicAttributes",
          "sns:ListTopics",
          "s3:*",
          "logs:*",
          "glue:Get*"
          ]
        Effect = "Allow"
        Resource = "*"
      }
    ]
  })
}

#역할 생성
resource "aws_iam_role" "cal-and-send-cur-role" {
  name = "cal-and-send-cur-role"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "lambda.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]})
}

#athena query 및 환율 계산 후 amazon sns에 message를 보내는 Lambda 생성
resource "aws_lambda_function" "lambda_function_send_cur" {
  function_name = "query_cur_lambda"
  role = aws_iam_role.cal-and-send-cur-role.arn
  runtime = "python3.9"
  handler = "calandsend.main_handler"
  filename = "calandsend.zip"
  source_code_hash = filebase64sha256("calandsend.zip")
  timeout = 10

  # lambda에 라이브러리 layer 추가
  layers = [aws_lambda_layer_version.boto_requests_layer.arn]
}

#라이브러리 추가를 위한 layer 생성
resource "aws_lambda_layer_version" "boto_requests_layer" {
  layer_name = "boto_requests_layer"
  description = "boto3 and requests library layer"
  compatible_runtimes = ["python3.9"]

  # s3에 업로드된 라이브러리로 layer 생성
  s3_bucket = aws_s3_bucket.billing_report_bucket.bucket
  s3_key    = "python.zip" 
}

#eventbridge 추가 
resource "aws_cloudwatch_event_rule" "oper_lambda" {
  name = "oper_lambda"
  schedule_expression = "cron(0 01 * * ? *)"
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.oper_lambda.name
  target_id = "cur_lambda_target"
  arn       = aws_lambda_function.lambda_function_send_cur.arn
}

# eventbridge와 lambda 연결을 위한 permission 등록
resource "aws_lambda_permission" "event_to_lambda" {
  statement_id  = "eventPermission"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function_send_cur.arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.oper_lambda.arn
}

# sns만 서울 region에서 생성하기 위한 provider 선언
provider "aws" {
  alias  = "sns_provider"
  region = "ap-northeast-2"
  access_key = var.test_access_key
  secret_key = var.test_secret_key
}

#Amazon SNS topic 및 subscription 생성
resource "aws_sns_topic" "billing_report_topic" {
  name = "billing_report"
  provider = aws.sns_provider
}

resource "aws_sns_topic_subscription" "subscription_endpoint" {
  topic_arn = aws_sns_topic.billing_report_topic.arn
  protocol = "email"
  endpoint = "cuyu9779@gmail.com"
  provider = aws.sns_provider
}