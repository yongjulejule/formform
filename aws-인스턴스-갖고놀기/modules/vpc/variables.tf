variable "region" {
  type        = string
  description = "The AWS region to deploy the VPC in"
}

variable "cidr_block" {
  type        = string
  description = "The CIDR block for the VPC"
  default     = "10.0.0.0/16"
}
