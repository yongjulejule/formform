output "instance_id" {
  value = aws_instance.controller.id
}

output "controller_public_ip" {
  value = aws_eip.controller_eip.public_ip
}
