output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "subnet_id" {
  value = aws_subnet.subnet.id
}

output "vpc_cidr" {
  value = aws_vpc.vpc.cidr_block
}
