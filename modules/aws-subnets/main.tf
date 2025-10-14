locals {
  # ngw_flags = [for s in var.subnets : s.attach_nat_gw]

  # create_eip_for_nat = anytrue(ngw_flags)

  subnet_routes_flat = merge([
    for s in var.subnets : {
      for idx, route in coalesce(s.routes, []) :
      "${s.name}-${idx}" => merge(route, { subnet_name = s.name })
    }
  ]...)
}
data "aws_availability_zones" "available" {
  state = "available"
}

# create subnets
resource "aws_subnet" "this" {
  for_each = { for idx, subnet in var.subnets : subnet.name => {
    cidr     = subnet.cidr
    name     = subnet.name
    az_index = idx
  } }

  vpc_id            = var.vpc_id
  cidr_block        = each.value.cidr
  availability_zone = data.aws_availability_zones.available.names[each.value.az_index % length(data.aws_availability_zones.available.names)]

  tags = merge(
    var.tags,
    {
      Name = each.value.name
    }
  )
}

# create a route table for each subnet
resource "aws_route_table" "this" {
  for_each = {
    for s in var.subnets : s.name => s
  }

  vpc_id = var.vpc_id

  tags = var.tags
}


# create routes for each subnet
resource "aws_route" "this" {
  for_each = local.subnet_routes_flat
  /*
  {
    "subnet-a-01" = {
      cidr = "0.0.0.0/0"
      gateway_id = "id"
      nat_gateway_id = "id"
      destination_cidr_block = "10.0.0.0/16"
    }
  }
  */

  route_table_id         = aws_route_table.this[each.value.subnet_name].id
  destination_cidr_block = each.value.destination_cidr_block
  gateway_id             = each.value.gateway_id
  nat_gateway_id         = each.value.nat_gateway_id
}

# associate routes to route tables
resource "aws_route_table_association" "this" {
  for_each = {
    for s in var.subnets : s.name => s
  }

  subnet_id      = aws_subnet.this[each.key].id
  route_table_id = aws_route_table.this[each.key].id
}

resource "aws_eip" "nat_ip" {
  for_each = {
    for idx, s in var.subnets :
    s.name => s if s.attach_nat_gw == true
  }
  domain = "vpc"
}

# associate subnets with nat gateway
resource "aws_nat_gateway" "this" {
  for_each = {
    for idx, s in var.subnets :
    s.name => s if s.attach_nat_gw == true
  }
  subnet_id     = aws_subnet.this[each.key].id
  allocation_id = aws_eip.nat_ip[each.key].id

  tags = var.tags
}
