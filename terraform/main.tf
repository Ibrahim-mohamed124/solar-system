resource "aws_vpc" "DEV_ENV_VPC" {
  cidr_block           = var.VPC_CIDR
  enable_dns_hostnames = true
  tags = {
    Name = "DEV_ENV_VPC"
  }
}

resource "aws_subnet" "DEV_ENV_SUBNET" {
  vpc_id     = aws_vpc.DEV_ENV_VPC.id
  cidr_block = var.SUBNET_CIDR
  tags = {
    Name = "DEV_ENV_SUBNET"
  }
}
resource "aws_internet_gateway" "DEV_ENV_GW" {
  vpc_id = aws_vpc.DEV_ENV_VPC.id
  tags = {
    Name = "DEV_ENV_GW"
  }
}
resource "aws_route_table" "DEV_ENV_PUBLIC_ROUTE_TABLE" {
  vpc_id = aws_vpc.DEV_ENV_VPC.id
  tags = {
    Name = "DEV_ENV_PUBLIC_ROUTE_TABLE"
  }
}
resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.DEV_ENV_PUBLIC_ROUTE_TABLE.id
  destination_cidr_block = "0.0.0.0/0" # All traffic to the internet
  gateway_id             = aws_internet_gateway.DEV_ENV_GW.id
}
resource "aws_route_table_association" "public_subnets" {
  subnet_id      = aws_subnet.DEV_ENV_SUBNET.id
  route_table_id = aws_route_table.DEV_ENV_PUBLIC_ROUTE_TABLE.id
}
resource "aws_security_group" "DEV_ENV_EC2_SECURITY_GROUP" {
  name   = "DEV_ENV_EC2_SECURITY_GROUP"
  vpc_id = aws_vpc.DEV_ENV_VPC.id
  dynamic "ingress" {
    for_each = var.ALLOWED_PORTS
    iterator = port
    content {
      from_port   = port.value
      to_port     = port.value
      cidr_blocks = ["0.0.0.0/0"]
      protocol    = "tcp"
    }
  }
}
resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.DEV_ENV_EC2_SECURITY_GROUP.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}
data "aws_ami" "RedHat" {
  most_recent = true
  owners      = ["309956199498"] # Red Hat
  filter {
    name   = "name"
    values = ["RHEL-9.3.0_HVM-20231207-x86_64-20-Hourly2-GP3"]
  }
}
resource "aws_key_pair" "JENKINS_KEY" {
  key_name   = "JENKINS_KEY"
  public_key = file(var.KEY_PATH)

}
resource "aws_instance" "DEV_ENV_EC2_INSTANCE" {
  ami                         = data.aws_ami.RedHat.id
  key_name                    = "JENKINS_KEY"
  instance_type               = var.INSTANCE_TYPE
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.DEV_ENV_EC2_SECURITY_GROUP.id]
  subnet_id                   = aws_subnet.DEV_ENV_SUBNET.id
  tags = {
    Name = "DEV_ENV_EC2_INSTANCE"
  }
  user_data = <<-EOF
  #!/bin/bash
  sudo yum update -y
  EOF

}

resource "aws_s3_bucket" "reports-bucket" {
  bucket = "securityreportsjenkins1"
  

  tags = {
    Name        = "Securit_reports"
    Environment = "Dev"
  }
}
