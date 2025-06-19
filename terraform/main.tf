terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "react-todo-app"
      ManagedBy   = "Terraform"
      Environment = "production"
    }
  }

}

# S3 Bucket Configuration
resource "aws_s3_bucket" "react_app" {
  bucket = var.bucket_name
  tags = {
    Name        = "React Todo App Bucket"
    Environment = "Production"
  }

  lifecycle {
    prevent_destroy = false # Set to true in production
  }
}

resource "aws_s3_bucket_ownership_controls" "react_app" {
  bucket = aws_s3_bucket.react_app.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "react_app" {
  bucket = aws_s3_bucket.react_app.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "react_app" {
  bucket = aws_s3_bucket.react_app.bucket
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_acl" "react_app" {
  depends_on = [
    aws_s3_bucket_ownership_controls.react_app,
    aws_s3_bucket_public_access_block.react_app
  ]
  bucket = aws_s3_bucket.react_app.bucket
  acl    = "public-read"
}

# CloudFront Configuration
resource "aws_cloudfront_origin_access_identity" "react_app" {
  comment = "OAI for ${var.bucket_name}"
}

resource "aws_cloudfront_distribution" "react_app" {
  origin {
    domain_name = aws_s3_bucket.react_app.bucket_regional_domain_name
    origin_id   = "S3-${aws_s3_bucket.react_app.bucket}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.react_app.cloudfront_access_identity_path
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  comment             = "React Todo App CDN"
  wait_for_deployment = true

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.react_app.bucket}"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    response_headers_policy_id = "67f7725c-6f97-4210-82d7-5512b31e9d03"
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
    minimum_protocol_version      = "TLSv1.2_2021"
  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  provisioner "local-exec" {
    command = "echo 'CloudFront distribution is being deployed. This may take up to 30 minutes.'"
  }
}

# S3 Bucket Policy for CloudFront Access Only
resource "aws_s3_bucket_policy" "cloudfront_access" {
  bucket = aws_s3_bucket.react_app.bucket
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.react_app.iam_arn
        }
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.react_app.arn}/*"
      }
    ]
  })

  depends_on = [
    aws_cloudfront_origin_access_identity.react_app
  ]
}

# File Upload with enhanced error handling
resource "null_resource" "upload_files" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command    = "aws s3 sync ../build s3://${aws_s3_bucket.react_app.bucket} --delete"
    on_failure = continue
  }

  depends_on = [
    aws_s3_bucket_policy.cloudfront_access,
    aws_cloudfront_distribution.react_app
  ]
}