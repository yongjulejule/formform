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

resource "aws_security_group" "public_sg" {
  vpc_id = var.vpc_id
  ingress {
    description = "Allow all inbound traffic from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow all inbound traffic from VPC"
    from_port   = 0
    to_port     = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "private_sg" {
  vpc_id = var.vpc_id
  ingress {
    description = "Allow all inbound traffic from VPC"
    from_port   = 0
    to_port     = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow all inbound traffic from VPC"
    from_port   = 0
    to_port     = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
  
# resource "aws_security_group" "allow_ssh" {
#   vpc_id = var.vpc_id
#   ingress {
#     description = "SSH from VPC"
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# resource "aws_security_group" "allow_outbound" {
#   vpc_id = var.vpc_id
#   egress {
#     description = "Allow all outbound traffic by default"
#     from_port   = 0
#     to_port     = 65535
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# resource "aws_security_group" "allow_inboud_from_vpc" {
#   vpc_id = var.vpc_id
#   ingress {
#     description = "Allow all inbound traffic from VPC"
#     from_port   = 0
#     to_port     = 65535
#     protocol    = "tcp"
#     cidr_blocks = [var.vpc_cidr]
#   }
# }

# resource "aws_security_group" "allow_all" {
#   vpc_id = var.vpc_id
#   ingress {
#     description = "Allow all inbound traffic from VPC"
#     from_port   = 0
#     to_port     = 65535
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   egress {
#     description = "Allow all outbound traffic by default"
#     from_port   = 0
#     to_port     = 65535
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }


resource "aws_instance" "controller" {
  ami                    = data.aws_ami.latest_amazon_linux.id
  instance_type          = "t3.medium"
  subnet_id              = var.public_subnet_id
  # vpc_security_group_ids = [aws_security_group.allow_ssh.id, aws_security_group.allow_outbound.id, aws_security_group.allow_inboud_from_vpc.id]
  vpc_security_group_ids = [aws_security_group.public_sg.id]
  key_name               = "controller-key-pair"
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name


  #user_data = file("${path.module}/../scripts/init-controller.sh")

  tags = {
    Name = "controller-from-terraform"
  }
}

resource "null_resource" "controller_provisioner" {
  depends_on = [ aws_instance.controller ]
  
  provisioner "local-exec" {
    command = "echo ${aws_instance.controller.public_ip} > ../controller_ip.txt"
  }
  provisioner "file" {
      source      = "${path.module}/../scripts/init-controller.sh"
      destination = "/tmp/init-controller.sh"
      connection {
        host = aws_eip.controller_eip.public_ip
        type = "ssh"
        user = "ec2-user"
        private_key = data.local_file.controller_key_pair.content
      }
  }
  
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/init-controller.sh",
      "sudo /tmp/init-controller.sh",
      "mkdir -p $HOME/.kube",
      "sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config",
      "sudo chown $(id -u):$(id -g) $HOME/.kube/config",
      "kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/calico.yaml",
     ]
     connection {
      host = aws_eip.controller_eip.public_ip
      type = "ssh"
      user = "ec2-user"
      private_key = data.local_file.controller_key_pair.content
     }
  }
}

data "local_file" "controller_key_pair" {
    filename = pathexpand("~/.ssh/controller-key-pair")
}

resource "aws_instance" "node" {
  ami                    = data.aws_ami.latest_amazon_linux.id
  instance_type          = "t3.small"
  subnet_id              = var.private_subnet_id
  # vpc_security_group_ids = [aws_security_group.allow_ssh.id, aws_security_group.allow_outbound.id, aws_security_group.allow_inboud_from_vpc.id]
  vpc_security_group_ids = [aws_security_group.private_sg.id]
  key_name               = "controller-key-pair"
  count                  = 2
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
  associate_public_ip_address = true

  depends_on = [ null_resource.controller_provisioner ]

  user_data = file("${path.module}/../scripts/init-worker.sh")

  tags = {
    Name = "node-from-terraform"
  }
}

resource "aws_eip" "controller_eip" {
  instance = aws_instance.controller.id
}

# IAM
resource "aws_iam_role" "ec2_role" {
  name = "ec2_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "parameter_store_access" {
  name        = "ParameterStoreAccess"
  description = "Allows access to Parameter Store"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:PutParameter",
        "ssm:GetParameter",
        "ssm:DescribeParameters"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "parameter_store_access_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.parameter_store_access.arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_profile"
  role = aws_iam_role.ec2_role.name
}
