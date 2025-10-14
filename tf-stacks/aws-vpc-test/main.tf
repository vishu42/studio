locals {
  tags = {
    environment = "development",
    managedBy = "terraform"
  }
}

module "aws-vpc" {
  count      = 1
  source     = "../../modules/aws-vpc"
  vpc_name   = "test-vpc"
  vpc_cidr   = "10.2.0.0/16"
  create_igw = true
  tags = local.tags
}

module "aws-public-subnet" {
  count = 0
  source = "../../modules/aws-subnets"
  vpc_id = module.aws-vpc[0].vpc_id
  vpc_name = "test-vpc"
  subnets = [ {
    name = "public-subnet"
    cidr = "10.2.0.0/24"
    attach_nat_gw = true
    routes = [ {
      gateway_id = module.aws-vpc[0].igw_id
      destination_cidr_block = "0.0.0.0/0"
    } ]
  } ]
  tags = local.tags
}

module "aws-private-subnet" {
  count = 0
  source = "../../modules/aws-subnets"
  vpc_id = module.aws-vpc[0].vpc_id
  vpc_name = "test-vpc"
  subnets = [ {
    name = "private-subnet"
    cidr = "10.2.8.0/24"
    routes = [ {
      nat_gateway_id = module.aws-public-subnet[0].nat_gateway_map["public-subnet"].id
      destination_cidr_block = "0.0.0.0/0"
    } ]
  } ]
  tags = local.tags
}