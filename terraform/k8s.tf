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
  cidr_block             = var.public_subnet_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone      = data.aws_availability_zones.available.names[count.index]
}

resource "aws_subnet" "private" {
  count                  = 3
  vpc_id                 = aws_vpc.main.id
  cidr_block             = var.private_subnet_cidrs[count.index]
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
  private_ip    = var.master_ips[count.index]
  user_data = file("preconfig.sh")
  tags = {
    Name = "master-node-${count.index + 1}"
  }
  root_block_device {
    volume_size = 30 # Size in GB
    volume_type = "gp2" # General Purpose SSD
  }
}

resource "aws_instance" "worker" {
  count         = 3
  ami           = "ami-0e2c8caa4b6378d8c" # Replace with a valid AMI ID
  instance_type = "t2.medium"
  subnet_id     = aws_subnet.private[count.index].id
  security_groups = [aws_security_group.open_all.id]
  private_ip    = var.worker_ips[count.index]
  user_data = file("preconfig.sh")
  tags = {
    Name = "worker-node-${count.index + 1}"
  }
  root_block_device {
    volume_size = 30 # Size in GB
    volume_type = "gp2" # General Purpose SSD
  }
}

resource "aws_instance" "Harbor" {
  count         = 1
  ami           = "ami-0e2c8caa4b6378d8c" # Replace with a valid AMI ID
  instance_type = "t2.large"
  subnet_id     = aws_subnet.public[count.index].id
  security_groups = [aws_security_group.open_all.id]
  key_name = data.aws_key_pair.keypair.key_name
  user_data = file("${path.module}/../harbor/install.sh")
  tags = {
    Name = "Harbor"
  }
  root_block_device {
    volume_size = 30 # Size in GB
    volume_type = "gp2" # General Purpose SSD
  }
}

resource "aws_eip_association" "Harbor_eip_association" {
  instance_id   = aws_instance.Harbor[0].id
  allocation_id = "eipalloc-0a056829a033c1102" # Replace with your existing EIP allocation ID
}

resource "aws_instance" "Ansible" {
  count         = 1
  ami           = "ami-0e2c8caa4b6378d8c" # Replace with a valid AMI ID
  instance_type = "t2.medium"
  subnet_id     = aws_subnet.public[count.index].id
  security_groups = [aws_security_group.open_all.id]
  key_name = data.aws_key_pair.keypair.key_name
  provisioner "file" {
    source      = "${path.module}/../ansible/"         
    destination = "/home/ubuntu/"   
    connection {
      type        = "ssh"
      host        = self.public_ip  
      user        = "ubuntu"
      private_key = file("${var.key_pair}")
    }
  }
  user_data = file("${path.module}/../ansible/install.sh")
  depends_on = [aws_lb.nlb, local_file.config_yaml, aws_instance.master, aws_instance.worker]
  tags = {
    Name = "Ansible"
  }
  root_block_device {
    volume_size = 30 # Size in GB
    volume_type = "gp2" # General Purpose SSD
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
resource "aws_route_table_association" "private" {
  count          = 3
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "public" {
  count          = 3
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "local_file" "config_yaml" {
  content = templatefile("${path.module}/00-init-playbook.yml.template", {
    nlb_domain = aws_lb.nlb.dns_name
  })
  filename = "${path.module}/../ansible/00-init-playbook.yml"
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

output "load_balancer_dns" {
  value = aws_lb.nlb.dns_name
}

output "target_group_arn" {
  value = aws_lb_target_group.tg.arn
}

