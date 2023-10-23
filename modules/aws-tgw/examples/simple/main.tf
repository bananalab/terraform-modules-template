
provider "aws" {
  default_tags {
    tags = {
      Name = "aws-tgw-module-example"
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
  vpc_cidr               = "172.16.0.0/16"
  vpc_name               = "example"
  client_cidrs           = ["10.0.0.0/8"]
  availability_zones     = local.availability_zones
  subnets_netmask_length = 20
}

output "result" {
  description = <<-EOT
    The result of the module.
  EOT
  value       = module.this.result
}
