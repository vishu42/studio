variable "vm_name" {
  type        = string
  description = "The name of the VM"
}

variable "subnet_id" {
  type        = string
  default     = null
  description = "The ID of the subnet"
}

variable "vpc_id" {
  type        = string
  default     = null
  description = "The ID of the VPC"
}