terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

data "aws_ami" "latest_amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023*x86_64"]
  }
}

resource "aws_security_group" "allow_ssh" {
  vpc_id = var.vpc_id
  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "allow_outbound" {
  vpc_id = var.vpc_id
  egress {
    description = "Allow all outbound traffic by default"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "allow_inboud_from_vpc" {
  vpc_id = var.vpc_id
  ingress {
    description = "Allow all inbound traffic from VPC"
    from_port   = 0
    to_port     = 65535
    protocol    = "traffic"
    cidr_blocks = [var.vpc_cidr]
  }
}

resource "aws_instance" "controller" {
  ami                    = data.aws_ami.latest_amazon_linux.id
  instance_type          = "t3.medium"
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.allow_ssh.id, aws_security_group.allow_outbound.id, aws_security_group.allow_inboud_from_vpc.id]
  key_name               = "controller-key-pair"

  user_data = file("../../scripts/init-controller.sh")

  tags = {
    Name = "controller-from-terraform"
  }
}

resource "null_resource" "init_cluster" { 
  depends_on = [aws_instance.controller]
  provisioner "remote-exec" {
    inline = [
      "sudo kubeadm token create --print-join-command | aws ssm put-parameter --name /k8s/join-command --type SecureString --value fileb:///dev/stdin"
    ]
    connection {
      type        = "ssh"
      host        = aws_instance.control_plane.public_ip
      user        = "ec2-user"
      private_key = file("~/.ssh/controller_key_pair")
    }

  }
}

resource "aws_instance" "node" {
  ami                    = data.aws_ami.latest_amazon_linux.id
  instance_type          = "t3.small"
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.allow_ssh.id, aws_security_group.allow_outbound.id, aws_security_group.allow_inboud_from_vpc.id]
  key_name               = "controller-key-pair"
  count                  = 2
  
  depends_on = [ null_resource.init_cluster ]

  user_data = file("../../scripts/init-controller.sh")

  tags = {
    Name = "node-from-terraform"
  }
}

resource "aws_eip" "controller_eip" {
  instance = aws_instance.controller.id
}



