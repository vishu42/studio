variable "vpc_a_id" {
  type        = string
  description = "The ID of the VPC A"
}

variable "vpc_b_id" {
  type        = string
  description = "The ID of the VPC B"
}

variable "subnet_a_ids" {
  type        = list(string)
  description = "The IDs of the subnets in VPC A"
}

variable "subnet_b_ids" {
  type        = list(string)
  description = "The IDs of the subnets in VPC B"
}

variable "vpc_a_rt_id" {
  type        = string
  default     = null
  description = "The ID of the route table in VPC A"
}

variable "vpc_b_rt_id" {
  type        = string
  default     = null
  description = "The ID of the route table in VPC B"
}