output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "subnet_ids" {
  value = values(aws_subnet.subnets)[*].id
}

output "vpc_cidr" {
  value = aws_vpc.vpc.cidr_block
}

output "subnets" {
  value = aws_subnet.subnets
}

output "subnet_map" {
  value = { for k, v in aws_subnet.subnets : k => {
    id                = v.id
    cidr_block        = v.cidr_block
    availability_zone = v.availability_zone
  } }
  description = "Map of subnet names to their details"
}

output "public_route_table_id" {
  value = aws_route_table.public[0].id
}