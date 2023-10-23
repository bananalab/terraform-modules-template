provider "aws" {
  default_tags {
    tags = {
      Terraformed = true
      Environment = "test"
      Name        = "vpc-module-test"
    }
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)
}

module "this" {
  source                 = "../../"
  name                   = "example"
  availability_zones     = local.availability_zones
  vpc_ip_address         = "10.11.0.0"
  vpc_netmask_length     = 16
  subnets_netmask_length = 20
  create_public_subnets  = true
  create_nat_gateways    = true
}
