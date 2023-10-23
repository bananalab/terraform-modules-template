/**
  * <!-- This will become the header in README.md
  *      Add a description of the module here.
  *      Do not include Variable or Output descriptions. -->
*/

locals {
  vpc_ip_address     = split("/", var.vpc_cidr)[0]
  vpc_netmask_length = split("/", var.vpc_cidr)[1]
}

module "vpc" {
  source                 = "../aws-vpc"
  name                   = var.vpc_name
  vpc_ip_address         = local.vpc_ip_address
  vpc_netmask_length     = local.vpc_netmask_length
  availability_zones     = var.availability_zones
  subnets_netmask_length = var.subnets_netmask_length
  create_public_subnets  = true
  create_nat_gateways    = true
}

resource "aws_ec2_transit_gateway" "this" {
  # #checkov:skip=CKV_AWS_331:The transit gateway is shared with the org.
  dns_support                     = "enable"
  vpn_ecmp_support                = "enable"
  default_route_table_association = "enable"
  default_route_table_propagation = "enable"
  auto_accept_shared_attachments  = "enable"
}

resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  vpc_id                                          = module.vpc.result.vpc.id
  subnet_ids                                      = [for subnet in module.vpc.result.private_subnets : subnet.id]
  transit_gateway_id                              = aws_ec2_transit_gateway.this.id
  dns_support                                     = "enable"
  transit_gateway_default_route_table_association = "true"
  transit_gateway_default_route_table_propagation = "true"
}


resource "aws_ram_resource_share" "this" {
  name = "${aws_ec2_transit_gateway.this.id} share"
}

data "aws_organizations_organization" "this" {}

resource "aws_ram_principal_association" "this" {
  principal          = data.aws_organizations_organization.this.arn
  resource_share_arn = aws_ram_resource_share.this.arn
}

resource "aws_ram_resource_association" "this" {
  resource_arn       = aws_ec2_transit_gateway.this.arn
  resource_share_arn = aws_ram_resource_share.this.arn
}

resource "aws_ec2_transit_gateway_route" "this" {
  destination_cidr_block         = "0.0.0.0/0"
  transit_gateway_attachment_id  = aws_ec2_transit_gateway_vpc_attachment.this.id
  transit_gateway_route_table_id = aws_ec2_transit_gateway.this.association_default_route_table_id
}

resource "aws_route" "this" {
  for_each               = toset(var.client_cidrs)
  route_table_id         = module.vpc.result.public_route_table.id
  destination_cidr_block = each.value
  transit_gateway_id     = aws_ec2_transit_gateway.this.id
}
