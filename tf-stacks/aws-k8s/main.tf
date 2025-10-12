locals {
  vms = [
    # "aws-vm-01",
    # "aws-vm-02",
    # "aws-vm-03",
  ]
}

module "aws-vm-jump-vpc" {
  count      = 0
  source     = "../../modules/aws-vpc"
  vpc_name   = "aws-vm-jump-vpc"
  vpc_cidr   = "10.1.0.0/16"
  enable_igw = true
  subnets = [
    { name = "aws-vm-jump-subnet", cidr = "10.1.1.0/24" },
  ]
  tags = {
    Environment = "development"
  }
}

module "aws-vm-jump" {
  count                       = 0
  source                      = "../../modules/aws-vm"
  vm_name                     = "aws-vm-jump"
  associate_public_ip_address = true
  additional_ingress_security_group_rules = [{
    description = "OpenVPN"
    port        = 1194
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }]
  subnet_id = module.aws-vm-jump-vpc[0].subnet_ids[0]
  vpc_id    = module.aws-vm-jump-vpc[0].vpc_id
}

# output the public ip of the jump vm
output "aws_vm_jump_public_ip" {
  value       = try(module.aws-vm-jump[0].vm_public_ip, null)
  description = "Public IP address of the jump VM"
}


module "aws-k8s-vpc" {
  count      = 0
  source     = "../../modules/aws-vpc"
  vpc_name   = "aws-k8s-vpc"
  vpc_cidr   = "10.0.0.0/16"
  enable_igw = true
  subnets = [
    { name = "aws-k8s-nodes-subnet", cidr = "10.0.1.0/24" },
  ]
  tags = {
    Environment = "development"
  }
}

module "aws-k8s-nodes" {
  for_each  = toset(local.vms)
  source    = "../../modules/aws-vm"
  vm_name   = each.value
  subnet_id = module.aws-k8s-vpc[0].subnet_ids[0]
  vpc_id    = module.aws-k8s-vpc[0].vpc_id
}

output "aws_vm_public_ip" {
  value       = [for vm in module.aws-k8s-nodes : vm.vm_public_ip]
  description = "Public IP addresses of the VMs"
}

# vpc peer
module "aws-vpc-peer" {
  count        = 0
  source       = "../../modules/aws-vpc-peer"
  vpc_a_id     = module.aws-vm-jump-vpc[0].vpc_id
  vpc_b_id     = module.aws-k8s-vpc[0].vpc_id
  subnet_a_ids = module.aws-vm-jump-vpc[0].subnet_ids
  subnet_b_ids = module.aws-k8s-vpc[0].subnet_ids
  vpc_a_rt_id  = module.aws-vm-jump-vpc[0].public_route_table_id
  vpc_b_rt_id  = module.aws-k8s-vpc[0].public_route_table_id
}