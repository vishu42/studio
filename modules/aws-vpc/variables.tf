variable "vpc_name" {
  type        = string
  description = "The name of the VPC"
}

variable "vpc_cidr" {
  type        = string
  description = "The CIDR block of the VPC"
}

variable "subnets" {
  type = list(object({
    name = string
    cidr = string
  }))

  description = <<EOF
  A list of subnets to create.

  Example:
  subnets = [
    {
      name = "subnet-1"
      cidr = "10.0.1.0/24"
    }
    {
      name = "subnet-2"
      cidr = "10.0.2.0/24"
    }
  ]
  EOF
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to add to the VPC"
  default     = {}
}

variable "enable_igw" {
  type        = bool
  description = "Whether to enable the Internet Gateway"
  default     = false
}