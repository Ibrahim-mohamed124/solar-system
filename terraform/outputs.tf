output "DEV_ENV_EC2_INSTANCE_PUBLIC_IP" {
  value = aws_instance.DEV_ENV_EC2_INSTANCE.public_ip
}
