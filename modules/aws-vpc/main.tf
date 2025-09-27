# Create VPC
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    var.tags,
    {
      Name = var.vpc_name
    }
  )
}

# Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-igw"
    }
  )
}

# Get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# Create subnets
resource "aws_subnet" "subnets" {
  for_each = { for idx, subnet in var.subnets : subnet.name => {
    cidr     = subnet.cidr
    name     = subnet.name
    az_index = idx
  } }

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = each.value.cidr
  availability_zone = data.aws_availability_zones.available.names[each.value.az_index % length(data.aws_availability_zones.available.names)]

  tags = merge(
    var.tags,
    {
      Name = each.value.name
    }
  )
}

# Create route table for public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.vpc_name}-public-rt"
    }
  )
}

# Associate subnets with route table
resource "aws_route_table_association" "public" {
  for_each = aws_subnet.subnets

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}
