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
  attach_transit_gateway = true
  transit_gateway_id     = "tgw-01c8de5704729bc19"
  vpc_netmask_length     = 16
  subnets_netmask_length = 20
}
