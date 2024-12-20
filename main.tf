terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.41"
    }

    ansible = {
      version = "~> 1.3.0"
      source  = "ansible/ansible"
    }
  }
  backend "s3" {
    bucket = "tfpocbucket001"
    key    = "jenkins-pipeline/terraform.tfstate"
    region = "eu-north-1"
  }
}

provider "aws" {
  region = local.region
}

locals {
  region = "ap-south-2"

  ami           = "ami-03aaeb1f15623d169"
  instance_type = "t3.micro"
  workers_count = 2

  tags = {
    Name = "Jenkins"
    env  = "dev"
  }
}

#VPC
resource "aws_vpc" "jenkins_vpc" {
  cidr_block = "172.16.0.0/16"
  tags       = local.tags
}

#INTERNET GATEWAY (IGW) 
resource "aws_internet_gateway" "jenkins_igw" {
  vpc_id = aws_vpc.jenkins_vpc.id

  tags = local.tags
}

#SUBNET
resource "aws_subnet" "jenkins_public_subnet" {
  vpc_id                  = aws_vpc.jenkins_vpc.id
  cidr_block              = "172.16.1.0/24"
  map_public_ip_on_launch = true
  tags                    = local.tags
}

# ROUTE TABLE
resource "aws_route_table" "jenkins_route_table" {
  vpc_id = aws_vpc.jenkins_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.jenkins_igw.id
  }
  tags = local.tags
}

# subnet attachment to ROUTE TABLE
resource "aws_route_table_association" "jenkins_route_table_association" {
  depends_on = [
    aws_subnet.jenkins_public_subnet
  ]
  subnet_id      = aws_subnet.jenkins_public_subnet.id
  route_table_id = aws_route_table.jenkins_route_table.id
}

# SECURITY GROUP
resource "aws_security_group" "jenkins_sg" {
  vpc_id = aws_vpc.jenkins_vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags

}

# RSA KEY PAIR
resource "tls_private_key" "foo" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "foo" {
  key_name   = "id_rsa"
  public_key = tls_private_key.foo.public_key_openssh
}

output "ssh_key" {
  value     = tls_private_key.foo.private_key_pem
  sensitive = true
}

# CONTROL PLANE NETWORK INTERFACE
resource "aws_network_interface" "network_interface_jenkins" {
  subnet_id       = aws_subnet.jenkins_public_subnet.id
  security_groups = [aws_security_group.jenkins_sg.id]
  tags            = merge(local.tags, { Name = "Jenkins-ENI" })
}

# JENKINS INSTANCE
resource "aws_instance" "jenkins" {
  ami           = local.ami
  instance_type = local.instance_type
  key_name      = aws_key_pair.foo.key_name

  # Attach the network interface
  network_interface {
    network_interface_id = aws_network_interface.network_interface_jenkins.id
    device_index         = 0
  }

  tags = merge(local.tags, { Name = "Control-Plane" })
}

output "jenkins_ip" {
  value = aws_instance.jenkins.public_ip
}

# ansible ansible-inventory -i inventory.yml --list (show the inventory)
resource "ansible_host" "manager" {
  name   = aws_instance.jenkins.public_ip
  groups = ["manager"]
  variables = {
    ansible_user                 = "ubuntu"
    ansible_ssh_private_key_file = "id_rsa.pem"
    ansible_connection           = "ssh"
    ansible_ssh_common_args      = "-o StrictHostKeyChecking=no"
    ansible_python_interpreter   = "/usr/bin/python3"
  }
}
