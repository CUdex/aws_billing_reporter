variable "test_region" {}
variable "billing_region" {}
variable "test_access_key" {}
variable "test_secret_key" {}

provider "aws" {
    region = var.billing_region
    access_key = var.test_access_key
    secret_key = var.test_secret_key
}

# 버킷 생성
resource "aws_s3_bucket" "billing_report_bucket" {
  bucket = "billing-report-bucket-genians"
  tags = {
    Name        = "Billing Report Bucket"
  }
}

# 버킷 acl 생성
resource "aws_s3_bucket_acl" "bucket_acl_private" {
  bucket = aws_s3_bucket.billing_report_bucket.id
  acl    = "private"
}

#report 정의
resource "aws_s3_bucket_policy" "billing_report_bucket_policy" {
  bucket = aws_s3_bucket.billing_report_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject"
        ]
        Effect    = "Allow"
        Principal = {
          Service = "athena.amazonaws.com"
        }
        Resource  = [
          "${aws_s3_bucket.billing_report_bucket.arn}",
          "${aws_s3_bucket.billing_report_bucket.arn}/*"
        ]
      },
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject"
        ]
        Effect    = "Allow"
        Principal = {
          Service = "billingreports.amazonaws.com"
        }
        Resource  = [
          "${aws_s3_bucket.billing_report_bucket.arn}",
          "${aws_s3_bucket.billing_report_bucket.arn}/*"
        ]
      },
      {
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject"
        ]
        Effect    = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
        Resource  = [
          "${aws_s3_bucket.billing_report_bucket.arn}",
          "${aws_s3_bucket.billing_report_bucket.arn}/*"
        ]
      },
            {
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Effect    = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Resource  = [
          "${aws_s3_bucket.billing_report_bucket.arn}",
          "${aws_s3_bucket.billing_report_bucket.arn}/*"
        ]
      }
    ]
  })
}

# AWS Billing Report 생성
resource "aws_cur_report_definition" "cur_report_definition" {
  report_name                = "cur-report"
  time_unit                  = "DAILY"
  format                     = "Parquet"
  compression                = "Parquet"
  additional_schema_elements = []
  s3_bucket                  = aws_s3_bucket.billing_report_bucket.bucket
  s3_region                  = aws_s3_bucket.billing_report_bucket.region
  s3_prefix                  = "reportresult"
  report_versioning          = "OVERWRITE_REPORT"
}

# AWS Glue 데이터 카탈로그 생성
resource "aws_glue_catalog_database" "billing_database" {
  name = "billing_database"
}

#crawler 생성
resource "aws_glue_crawler" "cur_s3_crawler" {
  database_name = aws_glue_catalog_database.billing_database.name
  name          = "cur_s3_crawler"
  role          = aws_iam_role.glue_crawler_role.arn
  schedule      = "cron(0 1 * * ? *)"

  s3_target {
    path = "s3://${aws_s3_bucket.billing_report_bucket.bucket}"
    exclusions = [ 
      "**.yml",
      "**.csv",
      "**.metadata",
      "**/cost_and_usage_data_status/**",
      "**.sql",
      "**.json",
      "**.gz",
      "**.zip"
       ]
  }
}

# role 생성
resource "aws_iam_role" "glue_crawler_role" {
  name = "glue-crawler-role"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "glue.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]})
}

resource "aws_iam_role_policy" "glue_log_policy" {
  name   = "glue-log-policy"
  role = aws_iam_role.glue_crawler_role.name

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
      },
      {
        Action = [
          "glue:*"
        ]
        Effect   = "Allow"
        Resource = ["arn:aws:glue:*:*:*"]
      }
    ]
  })
}

# crawler role에 S3FullAccess 정책 추가
resource "aws_iam_role_policy_attachment" "glue_crawler_s3_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role       = aws_iam_role.glue_crawler_role.name
}