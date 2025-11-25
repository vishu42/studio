locals {

  vms = [
    {
      name = "aws-vm-large-01"
      instance_type = "t3.large"
    },
    {
      name = "aws-vm-large-02"
      instance_type = "t3.xlarge"
    },
    {
      name = "aws-vm-large-03"
      instance_type = "t3.xlarge"
    },
    {
      name = "aws-vm-large-04"
      instance_type = "t3.xlarge"
    }
  ]
  tags = {
    Environment = "development"
    managedBy   = "terraform"
  }
}

module "aws-vm-jump-vpc" {
  count      = 1
  source     = "../../modules/aws-vpc"
  vpc_name   = "aws-vm-jump-vpc"
  vpc_cidr   = "10.1.0.0/16"
  tags       = local.tags
  create_igw = true
}

# public subnet
module "aws-vm-jump-subnet" {
  count    = 1
  source   = "../../modules/aws-subnets"
  vpc_id   = module.aws-vm-jump-vpc[0].vpc_id
  vpc_name = "aws-vm-jump-vpc"
  subnets = [{
    name          = "aws-vm-jump-subnet"
    cidr          = "10.1.1.0/24"
    attach_nat_gw = true
    routes = [{
      gateway_id             = module.aws-vm-jump-vpc[0].igw_id
      destination_cidr_block = "0.0.0.0/0"
    }]
  }]
  tags = local.tags
}

# jump vm
module "aws-vm-jump" {
  count                       = 1
  source                      = "../../modules/aws-vm"
  vm_name                     = "aws-vm-jump"
  associate_public_ip_address = true
  additional_ingress_security_group_rules = [{
    description = "OpenVPN"
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "HTTP"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "HTTPS"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "8443"
      from_port   = 8443
      to_port     = 8443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }]
  additional_egress_security_group_rules = [{
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }]
  subnet_id = module.aws-vm-jump-subnet[0].subnet_ids[0]
  vpc_id    = module.aws-vm-jump-vpc[0].vpc_id
}

# output the public ip of the jump vm
output "aws_vm_jump_public_ip" {
  value       = try(module.aws-vm-jump[0].vm_public_ip, null)
  description = "Public IP address of the jump VM"
}

# private subnet
module "aws-k8s-subnet" {
  count    = 1
  source   = "../../modules/aws-subnets"
  vpc_id   = module.aws-vm-jump-vpc[0].vpc_id
  vpc_name = "aws-k8s-vpc"
  subnets = [{
    name = "aws-k8s-nodes-subnet"
    cidr = "10.1.3.0/24"
    routes = [{
      nat_gateway_id         = module.aws-vm-jump-subnet[0].nat_gateway_map["aws-vm-jump-subnet"].id
      destination_cidr_block = "0.0.0.0/0"
    }]
  }]
  tags = local.tags
}

module "aws-k8s-nodes" {
  for_each      = {
    for vm in local.vms : vm.name => vm.instance_type
  }
  source        = "../../modules/aws-vm-improved"
  vm_name       = each.key
  subnet_id     = module.aws-k8s-subnet[0].subnet_ids[0]
  vpc_id        = module.aws-vm-jump-vpc[0].vpc_id
  instance_type = each.value

  additional_ingress_security_group_rules = [{
    description = "All inbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    }

  ]
  additional_egress_security_group_rules = [
    {
      description = "All outbound traffic"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

output "aws_vm_private_ip" {
  value       = [for vm in module.aws-k8s-nodes : vm.vm_private_ip]
  description = "Private IP addresses of the VMs (k8s nodes)"
}
