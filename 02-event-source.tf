variable "admin_email_address" {
  type = "string"
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
          "athena:GetQueryExecution",
          "athena:GetQueryResults",
          "sns:Publish",
          "sns:GetTopicAttributes"
          ]
        Effect = "Allow"
        Resource = ["*"]
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

#Amazon SNS topic 및 subscription 생성
resource "aws_sns_topic" "billing_report_topic" {
  name = "billing_report"
  region = "ap-northeast-2"
}

resource "aws_sns_subscription" "example" {
  topic_arn = aws_sns_topic.billing_report_topic.arn
  protocol = "email"
  endpoint = "cuyu9779@gmail.com"
}

#athena query 및 환율 계산 후 amazon sns에 message를 보내는 Lambda 생성
resource "aws_lambda_function" "lambda_function_send_cur" {
  name = "query_cur_lambda"
  role = aws_iam_role.cal-and-send-cur-role.arn
  runtime = "Python 3.10"
  code = file("./calandsend.py")

  # lambda에 라이브러리 layer 추가
  layers = [aws_lambda_layer.boto_requests_layer.arn]
}

#라이브러리 추가를 위한 layer 생성
resource "aws_lambda_layer" "boto_requests_layer" {
  name = "boto_requests_layer"
  description = "My Lambda layer"
  compatible_runtimes = ["Python 3.10"]

  # The source archive for the layer.
  source_archive_bucket = aws_s3_bucket.billing_report_bucket.id
  source_archive_key = "python.zip"
}

#eventbridge 추가 
resource "aws_eventbridge_rule" "oper_lambda" {
  name = "oper_lambda"
  schedule_expression = "cron(0 01 * * ? *)"
}

resource "aws_eventbridge_rule_target" "my_target" {
  rule = aws_eventbridge_rule.oper_lambda.name
  target_arn = aws_lambda_function.lambda_function_send_cur.arn
}