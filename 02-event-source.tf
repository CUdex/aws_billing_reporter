variable "admin_email_address" {}

##eventbridge 생성

#lambda에 권한 생성
resource "aws_iam_role_policy" "cal-and-send-cur" {
  name   = "cal-and-send-cur"
  role = aws_iam_role.cal-and-send-cur-role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:PutLogEvents",
          "logs:CreateLogGroup", 
          "logs:CreateLogStream",
          "logs:AssociateKmsKey",
          "logs:DescribeLogStreams"
          ]
        Effect = "Allow"
        Resource = ["arn:aws:logs:*:*:*"]
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
                "Service": "athena.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]})
}

##athena query 및 환율 계산 후 amazon sns에 message를 보내는 Lambda 생성