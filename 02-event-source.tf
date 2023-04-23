variable "admin_email_address" {}

##eventbridge 생성

##시간 결과 값을 계산하는 Lambda 생성

##email 발신하는 Lambda 생성

##report를 쿼리하는 athena 생성
# athena 쿼리 결과 저장을 위한 버킷 생성
# resource "aws_s3_bucket" "billing_report_result" {
#   bucket = "billing-report-athena-result"
#   tags = {
#     Name        = "Billing Report query result"
#   }
# }

# # 버킷 acl 생성
# resource "aws_s3_bucket_acl" "bucket_result_acl_private" {
#   bucket = aws_s3_bucket.billing_report_result.id
#   acl    = "private"
# }

# # athena query result 저장 bucket
# resource "aws_s3_bucket_policy" "billing_report_result_policy" {
#   bucket = aws_s3_bucket.billing_report_result.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = [
#           "s3:GetBucketAcl",
#           "s3:GetBucketLocation",
#           "s3:GetBucketPolicy",
#           "s3:GetObject",
#           "s3:ListBucket",
#           "s3:PutObject"
#         ]
#         Effect    = "Allow"
#         Principal = {
#           Service = "athena.amazonaws.com"
#         }
#         Resource  = [
#           "${aws_s3_bucket.billing_report_bucket.arn}",
#           "${aws_s3_bucket.billing_report_bucket.arn}/*"
#         ]
#       },
#       {
#         Action = [
#           "s3:GetBucketAcl",
#           "s3:GetBucketLocation",
#           "s3:GetBucketPolicy",
#           "s3:GetObject",
#           "s3:ListBucket",
#           "s3:PutObject"
#         ]
#         Effect    = "Allow"
#         Principal = {
#           Service = "billingreports.amazonaws.com"
#         }
#         Resource  = [
#           "${aws_s3_bucket.billing_report_bucket.arn}",
#           "${aws_s3_bucket.billing_report_bucket.arn}/*"
#         ]
#       },
#       {
#         Action = [
#           "s3:GetBucketAcl",
#           "s3:GetBucketLocation",
#           "s3:GetBucketPolicy",
#           "s3:GetObject",
#           "s3:ListBucket",
#           "s3:PutObject"
#         ]
#         Effect    = "Allow"
#         Principal = {
#           Service = "glue.amazonaws.com"
#         }
#         Resource  = [
#           "${aws_s3_bucket.billing_report_bucket.arn}",
#           "${aws_s3_bucket.billing_report_bucket.arn}/*"
#         ]
#       }
#     ]
#   })
# }

# # athena query 생성
# resource "aws_athena_database" "athena_query_database" {
#   name   = "billing_data"
#   bucket = aws_s3_bucket.billing_report_result.id
# }

# resource "aws_athena_data_catalog" "billing_data_catalog_athena_info" {
#   name        = "billing-glue-data-catalog"
#   description = "Glue based Data Catalog"
#   type        = "GLUE"

#   parameters = {
#     "catalog-id" = aws_glue_catalog_database.billing_database.id
#   }
# }

# resource "aws_athena_workgroup" "example" {
#   name = "athena-query-workgroup"

#   configuration {
#     enforce_workgroup_configuration    = true
#     publish_cloudwatch_metrics_enabled = true

#     result_configuration {
#       output_location = "s3://${aws_s3_bucket.billing_report_result.bucket}/"
#     }
#   }
# }