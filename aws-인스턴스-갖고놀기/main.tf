terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-west-1"
  alias  = "usw1"
}

provider "aws" {
  region = "us-east-1"
  alias  = "use1"
}

resource "aws_instance" "ec2_us_west_1" {
  provider = aws.usw1
  // other configuration...
  instance_type = "t2.micro"

  tags = {
    Name = "ExampleAppServerInstance"
  }
}

resource "aws_instance" "ec2_us_east_1" {
  provider = aws.use1
  // other configuration...
  instance_type = "t2.micro"

  tags = {
    Name = "ExampleAppServerInstance"
  }
}
