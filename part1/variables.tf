variable "aws_region" {
  default = "ap-south-1"
}

variable "ami_id" {
  description = "Amazon Linux 2 AMI ID"
  default     = "ami-0dee22c13ea7a9a67" # ap-south-1 region
}

variable "instance_type" {
  default = "t2.micro"
}

variable "key_name" {
  description = "Name of your existing EC2 key pair"
  default     = "your-key-name"
}
