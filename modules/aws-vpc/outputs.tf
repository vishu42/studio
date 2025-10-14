output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "vpc_cidr" {
  value = aws_vpc.vpc.cidr_block
}

output "tf_managed_rt" {
  value = try(aws_route_table.rt[0].id, null)
}

output "igw_id" {
  value = try(aws_internet_gateway.igw[0].id, null)
}
