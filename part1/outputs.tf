output "instance_public_ip" {
  value = aws_instance.flask_express.public_ip
}
