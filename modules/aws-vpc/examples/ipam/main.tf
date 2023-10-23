/**
  Create a simple VPC with IPAM addressing.
  >> Note: VPC destruction may timeout with IPAM integration.
*/

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

module "this" {
  source                 = "../../"
  name                   = "example"
  availability_zones     = slice(data.aws_availability_zones.available.names, 0, 2)
  ipam_pool_id           = "ipam-pool-04c7e976c8ae04494"
  vpc_netmask_length     = 16
  subnets_netmask_length = 20
  create_public_subnets  = true
  create_nat_gateways    = true
}
