locals {
  vpc_a_rt_id = coalesce(var.vpc_a_rt_id, try(aws_route_table.rt_a[0].id, null))
  vpc_b_rt_id = coalesce(var.vpc_b_rt_id, try(aws_route_table.rt_b[0].id, null))
}


data "aws_vpc" "vpc_a" {
  id = var.vpc_a_id
}

data "aws_vpc" "vpc_b" {
  id = var.vpc_b_id
}

resource "aws_route_table" "rt_a" {
  count  = var.vpc_a_rt_id == null ? 1 : 0
  vpc_id = var.vpc_a_id
}

resource "aws_route_table" "rt_b" {
  count  = var.vpc_b_rt_id == null ? 1 : 0
  vpc_id = var.vpc_b_id
}

resource "aws_route_table_association" "rt_a_association" {
  for_each       = toset(var.subnet_a_ids)
  subnet_id      = each.value
  route_table_id = local.vpc_a_rt_id
}

resource "aws_route_table_association" "rt_b_association" {
  for_each       = toset(var.subnet_b_ids)
  subnet_id      = each.value
  route_table_id = local.vpc_b_rt_id
}

resource "aws_vpc_peering_connection" "vpc_peering_connection" {
  vpc_id      = var.vpc_a_id
  peer_vpc_id = var.vpc_b_id
  auto_accept = true
}

# configure routes
resource "aws_route" "route_a_to_b" {
  route_table_id            = local.vpc_a_rt_id
  destination_cidr_block    = data.aws_vpc.vpc_b.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering_connection.id
}

resource "aws_route" "route_b_to_a" {
  route_table_id            = local.vpc_b_rt_id
  destination_cidr_block    = data.aws_vpc.vpc_a.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.vpc_peering_connection.id
}