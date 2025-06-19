output "cloudfront_url" {
  description = "CloudFront Distribution URL"
  value       = "https://${aws_cloudfront_distribution.react_app.domain_name}"
}

output "s3_website_url" {
  description = "S3 Website URL"
  value       = "http://${aws_s3_bucket.react_app.bucket}.s3-website-${var.aws_region}.amazonaws.com"
}