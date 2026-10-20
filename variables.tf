variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "ap-south-1"
}
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}
variable "min_size" {
  description = "Minimum number of EC2 instances"
  type        = number
  default     = 2
}
variable "max_size" {
  description = "Maximum number of EC2 instances"
  type        = number
  default     = 4
}
variable "desired_capacity" {
  description = "Initial number of EC2 instances"
  type        = number
  default     = 2
}
