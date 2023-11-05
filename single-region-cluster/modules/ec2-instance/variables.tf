variable "region" {
  type = string
}

variable "vpc_id" {
  type        = string
  description = "The VPC ID to launch the EC2 instance in"
}

variable "vpc_cidr" {
  type        = string
  description = "The VPC CIDR block"
}

variable "subnet_id" {
  type        = string
  description = "The subnet ID to launch the EC2 instance in"
}

variable "subnet_egress_id" {
  type        = string
  description = "The subnet ID to launch the EC2 instance in for egress"
}

