variable "subnets" {
  type = list(object({
    name          = string
    cidr          = string
    attach_nat_gw = optional(bool, false)
    routes = optional(list(object({
      gateway_id             = optional(string)
      nat_gateway_id         = optional(string)
      destination_cidr_block = string
    })))
  }))
}

variable "vpc_id" {
  type = string
}

variable "vpc_name" {
  type = string
}

variable "tags" {
  type        = map(string)
  description = "a map of tags to add to the subnets"
  default = {
    "ManagedBy" = "terraform"
  }
}
