locals {
  vms = [
    "aws-vm-01",
    "aws-vm-02",
    "aws-vm-03",
  ]
}

module "aws-vpc" {
  source   = "../../modules/aws-vpc"
  vpc_name = "aws-k8s-vpc"
  vpc_cidr = "10.0.0.0/16"
  subnets = [
    { name = "aws-k8s-subnet-01", cidr = "10.0.1.0/24" },
  ]
  tags = {
    Environment = "development"
  }
}

module "aws-vm" {
  for_each  = toset(local.vms)
  source    = "../../modules/aws-vm"
  vm_name   = each.value
  subnet_id = module.aws-vpc.subnet_ids[0]
  vpc_id    = module.aws-vpc.vpc_id
}

output "aws_vm_public_ip" {
  value = [for vm in module.aws-vm : vm.vm_public_ip]
}