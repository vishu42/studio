locals {
  vms = [
    "aws-vm-01",
    "aws-vm-02",
    "aws-vm-03",
  ]
}

module "aws-vm" {
  for_each = toset(local.vms)
  source = "../../modules/aws-vm"
  vm_name = each.value
}

output "aws_vm_public_ip" {
  value = [for vm in module.aws-vm : vm.vm_public_ip]
}