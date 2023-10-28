variable "regions" {
  type    = list(string)
  default = ["us-west-1", "us-east-1"]
}

provider "aws" {
  alias  = "us_west_1"
  region = "us-west-1"
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

module "ec2_instances_us_west_1" {
  source   = "./modules/ec2_instance"
  providers = {
    aws = aws.us_west_1
  }
  
  region = "us-west-1"
}

module "ec2_instances_us_east_1" {
  source   = "./modules/ec2_instance"
  providers = {
    aws = aws.us_east_1
  }
  region = "us-east-1"
}

