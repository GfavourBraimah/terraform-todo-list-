variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
  default = "devops-todo-list349"

}
variable "allowed_referers" {
  description = "List of allowed referers for S3 access"
  type        = list(string)
  default     = []
}