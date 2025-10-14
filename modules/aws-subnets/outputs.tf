output "subnet_ids" {
  value = values(aws_subnet.this)[*].id
}

output "subnet_map" {
  value = { for k, v in aws_subnet.this : k => {
    id                = v.id
    cidr_block        = v.cidr_block
    availability_zone = v.availability_zone
  } }
  description = "Map of subnet names to their details"
}

output "nat_gateway_map" {
  value = aws_nat_gateway.this
}
