# aws-vpc

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

<!-- This will become the header in README.md
     Add a description of the module here.
     Do not include Variable or Output descriptions. -->

## Example

```hcl
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
```
<!-- markdownlint-disable -->

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_subnet_addrs"></a> [subnet\_addrs](#module\_subnet\_addrs) | hashicorp/subnets/cidr | ~> 1.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~>5.0 |

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~>1.5 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~>5.0 |

## Resources

| Name | Type |
|------|------|
| [aws_ec2_transit_gateway_vpc_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_transit_gateway_vpc_attachment) | resource |
| [aws_eip.nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_internet_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_nat_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_route.nat_gw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.transit_gw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route_table.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.nat_gw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.transit_gw](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_subnet.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_availability_zones"></a> [availability\_zones](#input\_availability\_zones) | Availability zones to create resources in. | `list(string)` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Name of the VPC.  Used to name various other resources. | `string` | n/a | yes |
| <a name="input_subnets_netmask_length"></a> [subnets\_netmask\_length](#input\_subnets\_netmask\_length) | The netmask length of the IPv4 CIDR you want to allocate to subnets.<br>Must be greater than `vpc_netmask_lengthh` | `string` | n/a | yes |
| <a name="input_vpc_netmask_length"></a> [vpc\_netmask\_length](#input\_vpc\_netmask\_length) | The netmask length of the IPv4 CIDR to allocate to this VPC. | `number` | n/a | yes |
| <a name="input_attach_transit_gateway"></a> [attach\_transit\_gateway](#input\_attach\_transit\_gateway) | Toggle Transit Gateway attachment.<br>Requires `transit_gateway_id`. | `bool` | `false` | no |
| <a name="input_create_nat_gateways"></a> [create\_nat\_gateways](#input\_create\_nat\_gateways) | Toggle nat gateway creation.<br>Conflicts with `transit_gateway_id`.<br>Requires `create_public_subnets`. | `bool` | `false` | no |
| <a name="input_create_public_subnets"></a> [create\_public\_subnets](#input\_create\_public\_subnets) | Toggle public subnet creation. | `bool` | `false` | no |
| <a name="input_ipam_pool_id"></a> [ipam\_pool\_id](#input\_ipam\_pool\_id) | The ID of an IPv4 IPAM pool you want to use for allocating this VPC's CIDR.<br>Conflicts with `vpc_ip_address`. | `string` | `null` | no |
| <a name="input_transit_gateway_id"></a> [transit\_gateway\_id](#input\_transit\_gateway\_id) | Transit gateway to connect to.<br>Requires `attach_transit_gateway`.<br>Conflicts with `create_nat_gateways`. | `string` | `null` | no |
| <a name="input_vpc_ip_address"></a> [vpc\_ip\_address](#input\_vpc\_ip\_address) | Base IP address block for VPC. Combined with `vpc_netmask_length` to form<br>CIDR for the VPC.<br>Conflicts with `ipam_pool_id`. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_result"></a> [result](#output\_result) | The result of the module. |


<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
