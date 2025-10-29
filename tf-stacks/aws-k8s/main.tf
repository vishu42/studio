locals {
  vms = [
    "aws-vm-01",
    "aws-vm-02",
    "aws-vm-03",
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
    port        = 1194
    protocol    = "udp"
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
  for_each  = toset(local.vms)
  source    = "../../modules/aws-vm"
  vm_name   = each.value
  subnet_id = module.aws-k8s-subnet[0].subnet_ids[0]
  vpc_id    = module.aws-vm-jump-vpc[0].vpc_id
  additional_ingress_security_group_rules = [{
    description = "Kubernetes"
    port        = 6443
    protocol    = "tcp"
    cidr_blocks = ["10.1.0.0/16"]
  }]
}

output "aws_vm_private_ip" {
  value       = [for vm in module.aws-k8s-nodes : vm.vm_private_ip]
  description = "Private IP addresses of the VMs (k8s nodes)"
}
