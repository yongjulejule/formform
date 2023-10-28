terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

data "aws_ami" "latest_amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

resource "aws_instance" "ec2" {
  ami           = data.aws_ami.latest_amazon_linux.id
  instance_type = "t2.micro"
  
  tags = {
    Name = "ec2-instance-from-terraform"
  }
  
  

  // ... other configurations
}
