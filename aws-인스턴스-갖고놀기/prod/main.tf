provider "aws" {
  alias  = "us_west_1"
  region = "us-west-1"
}

module "ec2_instances_us_west_1" {
  source   = "../modules/ec2-instance"
  providers = {
    aws = aws.us_west_1
  }
  region = "us-west-1"
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

module "ec2_instances_us_east_1" {
  source   = "../modules/ec2-instance"
  providers = {
    aws = aws.us_east_1
  }
  region = "us-east-1"
}


// declare vpc
module "vpc" {
  source             = "../../modules/vpc"
  cidr_block         = var.cidr_block
  availability_zone  = var.availability_zone
}
