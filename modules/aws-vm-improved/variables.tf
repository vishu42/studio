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

variable "instance_type" {
  type        = string
  default     = "t3.small"
  description = "The instance type of the VM"
}

variable "additional_ingress_security_group_rules" {
  type = list(object({
    description = optional(string)
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default     = []
  description = "A list of ingress security group rules"
}

variable "additional_egress_security_group_rules" {
  type = list(object({
    description = optional(string)
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default     = []
  description = "A list of egress security group rules"
}

variable "associate_public_ip_address" {
  type        = bool
  default     = false
  description = "Whether to associate a public IP address with the VM"
}