/**
  * <!-- This will become the header in README.md
  *      Add a description of the module here.
  *      Do not include Variable or Output descriptions. -->
*/


locals {
  new_bits             = var.subnets_netmask_length - var.vpc_netmask_length
  private_subnet_names = [for az in var.availability_zones : "${az}_private"]
  public_subnet_names  = [for az in var.availability_zones : "${az}_public"]
  public_subnets       = { for network in module.subnet_addrs.networks : trimsuffix(network.name, "_public") => network.cidr_block if endswith(network.name, "public") }
  private_subnets      = { for network in module.subnet_addrs.networks : trimsuffix(network.name, "_private") => network.cidr_block if endswith(network.name, "private") }
  networks             = [for subnet in concat(local.private_subnet_names, local.public_subnet_names) : { "new_bits" : local.new_bits, "name" : subnet }]
  base_cidr_block      = var.ipam_pool_id == null ? "${var.vpc_ip_address}/${var.vpc_netmask_length}" : aws_vpc.this.cidr_block
}

module "subnet_addrs" {
  #checkov:skip=CKV_TF_1:Not applicable
  source          = "hashicorp/subnets/cidr"
  version         = "~> 1.0"
  base_cidr_block = local.base_cidr_block
  networks        = local.networks
}

resource "aws_vpc" "this" {
  #checkov:skip=CKV2_AWS_11:TODO: Support flow logging
  #checkov:skip=CKV2_AWS_12:TODO: Restrict default SG
  cidr_block          = var.ipam_pool_id == null ? "${var.vpc_ip_address}/${var.vpc_netmask_length}" : null
  ipv4_ipam_pool_id   = var.ipam_pool_id == null ? null : var.ipam_pool_id
  ipv4_netmask_length = var.ipam_pool_id == null ? null : var.vpc_netmask_length
  tags = {
    Name = var.name
  }
}

resource "aws_internet_gateway" "this" {
  count  = var.create_public_subnets ? 1 : 0
  vpc_id = aws_vpc.this.id
}

resource "aws_subnet" "public" {
  for_each          = var.create_public_subnets ? local.public_subnets : {}
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = each.key
  #checkov:skip=CKV_AWS_130:Public subnet
  map_public_ip_on_launch = true
  tags = {
    Name = "${each.key}-public"
    Tier = "Public"
  }
}

resource "aws_route_table" "public" {
  count  = var.create_public_subnets ? 1 : 0
  vpc_id = aws_vpc.this.id
  tags = {
    Tier = "Public"
  }
}

resource "aws_route" "public" {
  count                  = var.create_public_subnets ? 1 : 0
  route_table_id         = aws_route_table.public[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this[0].id
}

resource "aws_route_table_association" "public" {
  for_each       = var.create_public_subnets ? aws_subnet.public : {}
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public[0].id
}

resource "aws_nat_gateway" "this" {
  for_each      = var.create_nat_gateways ? aws_subnet.public : {}
  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = each.value.id
  depends_on    = [aws_internet_gateway.this]
}

resource "aws_eip" "nat" {
  # checkov:skip=CKV2_AWS_19: Attached using allocation_id in NAT GWs
  for_each = var.create_nat_gateways ? aws_subnet.public : {}
  domain   = "vpc"
}

# Private subnet config

resource "aws_subnet" "private" {
  for_each          = local.private_subnets
  vpc_id            = aws_vpc.this.id
  cidr_block        = each.value
  availability_zone = each.key
  tags = {
    Name = "${each.key}-private"
    Tier = "Private"
  }
}

resource "aws_route_table" "private" {
  for_each = aws_subnet.private
  vpc_id   = aws_vpc.this.id
  tags = {
    Tier = "Private"
  }
}

resource "aws_route" "nat_gw" {
  for_each               = var.create_nat_gateways ? aws_route_table.private : {}
  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[each.key].id
}

resource "aws_route_table_association" "nat_gw" {
  for_each       = var.create_nat_gateways ? aws_route.nat_gw : {}
  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}

resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  count              = var.attach_transit_gateway ? 1 : 0
  subnet_ids         = [for subnet in aws_subnet.private : subnet.id]
  transit_gateway_id = var.transit_gateway_id
  vpc_id             = aws_vpc.this.id
}

resource "aws_route" "transit_gw" {
  for_each               = var.attach_transit_gateway ? aws_route_table.private : {}
  route_table_id         = each.value.id
  destination_cidr_block = "0.0.0.0/0"
  transit_gateway_id     = var.transit_gateway_id
}

resource "aws_route_table_association" "transit_gw" {
  for_each       = var.attach_transit_gateway ? aws_route.transit_gw : {}
  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}
