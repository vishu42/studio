variable "vpc_name" {
  type        = string
  description = "The name of the VPC"
}

variable "vpc_cidr" {
  type        = string
  description = "The CIDR block of the VPC"
}

variable "create_igw" {
  type    = bool
  default = false
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to add to the VPC"
  default = {
    "ManagedBy" = "terraform"
  }
}

variable "create_route_table" {
  type    = bool
  default = false
}


