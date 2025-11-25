data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# generate a ssh key pair
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ssh_key" {
  key_name   = "${var.vm_name}-ssh-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

# Write private key to ~/.ssh folder
resource "local_file" "private_key" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = pathexpand("~/.ssh/${var.vm_name}-ssh-key")
  file_permission = "0600"
}

# default security group to allow SSH traffic
resource "aws_security_group" "ssh_access" {
  name_prefix = "${var.vm_name}-ssh-sg"
  description = "Security group for SSH access to ${var.vm_name}"
  vpc_id      = var.vpc_id
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.vm_name}-ssh-sg"
  }
}

# additional security group rules
resource "aws_security_group" "additional_ingress_rules" {
  for_each = {
    for idx, rule in var.additional_ingress_security_group_rules :
    "${rule.from_port}-${rule.to_port}-${rule.protocol}" => rule
  }
  name_prefix = "${var.vm_name}-additional-ingress-sg"
  vpc_id      = var.vpc_id
  ingress {
    description = each.value.description
    from_port   = each.value.from_port
    to_port     = each.value.to_port
    protocol    = each.value.protocol
    cidr_blocks = each.value.cidr_blocks
  }

}
resource "aws_security_group" "additional_egress_rules" {
  for_each = {
    for idx, rule in var.additional_egress_security_group_rules :
    "${rule.from_port}-${rule.to_port}-${rule.protocol}" => rule
  }
  name_prefix = "${var.vm_name}-additional-egress-sg"
  vpc_id      = var.vpc_id
  egress {
    description = each.value.description
    from_port   = each.value.from_port
    to_port     = each.value.to_port
    protocol    = each.value.protocol
    cidr_blocks = each.value.cidr_blocks
  }
}

resource "aws_instance" "vm" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type # 2GB RAM, 2 vCPUs
  key_name                    = aws_key_pair.ssh_key.key_name
  vpc_security_group_ids      = concat([aws_security_group.ssh_access.id], values(aws_security_group.additional_ingress_rules)[*].id)
  subnet_id                   = var.subnet_id
  associate_public_ip_address = var.associate_public_ip_address

  tags = {
    Name = var.vm_name
  }
}
