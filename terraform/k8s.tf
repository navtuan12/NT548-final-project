provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "nt548-tf-state"
    key    = "vpc/nlb/terraform.tfstate"
    region = "us-east-1"
  }
}

data "aws_key_pair" "keypair" {
  key_name = "anhtuan"  # Replace with your existing key name in AWS
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
}

resource "aws_eip" "nat" {
  vpc = true
}

resource "aws_subnet" "public" {
  count                  = 3
  vpc_id                 = aws_vpc.main.id
  cidr_block             = cidrsubnet(aws_vpc.main.cidr_block, 3, count.index)
  map_public_ip_on_launch = true
  availability_zone      = data.aws_availability_zones.available.names[count.index]
}

resource "aws_subnet" "private" {
  count                  = 3
  vpc_id                 = aws_vpc.main.id
  cidr_block             = cidrsubnet(aws_vpc.main.cidr_block, 3, count.index + 3)
  availability_zone      = data.aws_availability_zones.available.names[count.index]
}

data "aws_availability_zones" "available" {}

resource "aws_security_group" "open_all" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "master" {
  count         = 3
  ami           = "ami-0e2c8caa4b6378d8c" # Replace with a valid AMI ID
  instance_type = "t2.medium"
  subnet_id     = aws_subnet.private[count.index].id
  security_groups = [aws_security_group.open_all.id]
  user_data = file("preconfig.sh")
  tags = {
    Name = "master-node-${count.index + 1}"
  }
}

resource "aws_instance" "worker" {
  count         = 3
  ami           = "ami-0e2c8caa4b6378d8c" # Replace with a valid AMI ID
  instance_type = "t2.medium"
  subnet_id     = aws_subnet.private[count.index].id
  security_groups = [aws_security_group.open_all.id]
  user_data = file("preconfig.sh")
  tags = {
    Name = "worker-node-${count.index + 1}"
  }
}

resource "aws_instance" "public_k8s" {
  count         = 2
  ami           = "ami-0e2c8caa4b6378d8c" # Replace with a valid AMI ID
  instance_type = "t2.medium"
  subnet_id     = aws_subnet.public[count.index].id
  security_groups = [aws_security_group.open_all.id]
  key_name = data.aws_key_pair.keypair.key_name
  tags = {
    Name = "public-k8s-node-${count.index + 1}"
  }
}

resource "aws_lb" "nlb" {
  name               = "nlb"
  internal           = false
  load_balancer_type = "network"
  security_groups    = [aws_security_group.open_all.id]
  subnet_mapping {
    subnet_id = aws_subnet.public[0].id
  }
  subnet_mapping {
    subnet_id = aws_subnet.public[1].id
  }
  subnet_mapping {
    subnet_id = aws_subnet.public[2].id
  }
}

resource "aws_lb_target_group" "tg" {
  name        = "tg"
  port        = 6443
  protocol    = "TCP"
  vpc_id      = aws_vpc.main.id
  health_check {
    protocol = "TCP"
    port     = 6443
  }
}

resource "aws_lb_target_group_attachment" "master" {
  count            = 3
  target_group_arn = aws_lb_target_group.tg.arn
  target_id        = aws_instance.master[count.index].id
  port             = 6443
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = 6443
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

resource "aws_route_table_association" "public" {
  count          = 3
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = 3
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnets" {
  value = aws_subnet.public[*].id
}

output "private_subnets" {
  value = aws_subnet.private[*].id
}

output "nat_gateway_id" {
  value = aws_nat_gateway.nat.id
}

output "internet_gateway_id" {
  value = aws_internet_gateway.igw.id
}

output "master_instance_ids" {
  value = aws_instance.master[*].id
}

output "worker_instance_ids" {
  value = aws_instance.worker[*].id
}

output "public_k8s_instance_ids" {
  value = aws_instance.public_k8s[*].id
}

output "public_k8s_public_ips" {
  value = aws_instance.public_k8s[*].public_ip
}

output "load_balancer_dns" {
  value = aws_lb.nlb.dns_name
}

output "target_group_arn" {
  value = aws_lb_target_group.tg.arn
}

