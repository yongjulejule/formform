provider "aws" {
  alias  = "us_west_1"
  region = "us-west-1"
}


module "vpc_us_west_1" {
  source   = "../modules/vpc"
  region   = "us-west-1"
  providers = {
    aws = aws.us_west_1
  }
}

module "ec2_instance_us_west_1" {
  source    = "../modules/ec2-instance"
  region    = "us-west-1"
  vpc_id    = module.vpc_us_west_1.vpc_id
  subnet_id = module.vpc_us_west_1.subnet_id
  providers = {
    aws = aws.us_west_1
  }
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

module "vpc_us_east_1" {
  source   = "../modules/vpc"
  region   = "us-east-1"
  providers = {
    aws = aws.us_east_1
  }
}

module "ec2_instance_us_east_1" {
  source    = "../modules/ec2-instance"
  region    = "us-east-1"
  vpc_id    = module.vpc_us_east_1.vpc_id
  subnet_id = module.vpc_us_east_1.subnet_id
  providers = {
    aws = aws.us_east_1
  }
}
