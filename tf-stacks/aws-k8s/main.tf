locals {
  vms = [
    # "aws-vm-01",
    # "aws-vm-02",
    # "aws-vm-03",
  ]
}

module "aws-vm-jump" {
  count = 1
  source = "../../modules/aws-vm"
  vm_name = "aws-vm-jump"
  additional_ingress_security_group_rules = [{
    description = "OpenVPN"
    port = 1194
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }]

}

# output the public ip of the jump vm
output "aws_vm_jump_public_ip" {
  value = try(module.aws-vm-jump[0].vm_public_ip, null)
  description = "Public IP address of the jump VM"
}


module "aws-vpc" {
  count = 0
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
  subnet_id = module.aws-vpc[0].subnet_ids[0]
  vpc_id    = module.aws-vpc[0].vpc_id
}

output "aws_vm_public_ip" {
  value = [for vm in module.aws-vm : vm.vm_public_ip]
  description = "Public IP addresses of the VMs"
}