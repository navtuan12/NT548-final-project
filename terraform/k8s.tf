provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "nt548-terraform-state"
    key    = "terraform.tfstate"
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
  allocation_id = "eipalloc-012b20943422f5d93" # Replace with your existing EIP allocation ID
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

resource "aws_eks_cluster" "demo" {
  name     = "demo"
  role_arn = "arn:aws:iam::439438480893:role/LabRole"

  vpc_config {
    subnet_ids = flatten([
      # For each index from 0..2, collect both public and private subnets
      for i in range(3) : [
        aws_subnet.public[i].id,
        aws_subnet.private[i].id
      ]
    ])
  }
}

resource "aws_eks_node_group" "private-nodes" {
  cluster_name    = aws_eks_cluster.demo.name
  node_group_name = "private-nodes"
  node_role_arn   = "arn:aws:iam::439438480893:role/LabRole"

  subnet_ids = flatten([
      # For each index from 0..2, collect both public and private subnets
      for i in range(3) : [
        aws_subnet.private[i].id
      ]
  ])

  capacity_type  = "ON_DEMAND"
  instance_types = ["t3.medium"]

  scaling_config {
    desired_size = 3
    max_size     = 5
    min_size     = 0
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    role = "general"
  }
}
