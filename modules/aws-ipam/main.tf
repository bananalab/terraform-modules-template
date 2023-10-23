/**
  * <!-- This will become the header in README.md
  *      Add a description of the module here.
  *      Do not include Variable or Output descriptions. -->
  Creates an Organizational shared IPAM.
*/

data "aws_region" "current" {}
data "aws_organizations_organization" "this" {}

locals {
  all_ipam_regions = distinct(concat([data.aws_region.current.name], var.ipam_regions))
}

resource "aws_vpc_ipam" "this" {
  dynamic "operating_regions" {
    for_each = local.all_ipam_regions
    content {
      region_name = operating_regions.value
    }
  }
}

resource "aws_vpc_ipam_pool" "this" {
  address_family = "ipv4"
  ipam_scope_id  = aws_vpc_ipam.this.private_default_scope_id
  locale         = data.aws_region.current.name
}

resource "aws_vpc_ipam_pool_cidr" "this" {
  ipam_pool_id = aws_vpc_ipam_pool.this.id
  cidr         = var.root_cidr
}

resource "aws_ram_resource_share" "this" {
  name = "${aws_vpc_ipam_pool.this.id} share"
}

resource "aws_ram_principal_association" "this" {
  principal          = data.aws_organizations_organization.this.arn
  resource_share_arn = aws_ram_resource_share.this.arn
}

resource "aws_ram_resource_association" "this" {
  resource_arn       = aws_vpc_ipam_pool.this.arn
  resource_share_arn = aws_ram_resource_share.this.arn
}
