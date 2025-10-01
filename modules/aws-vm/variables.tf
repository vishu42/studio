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

variable "additional_ingress_security_group_rules" {
  type = list(object({
    description = optional(string)
    port = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = []
  description = "A list of ingress security group rules"
}