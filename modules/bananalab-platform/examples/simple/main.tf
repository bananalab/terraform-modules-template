/**
  * Examples should illustrate typical use cases.
  * For multiple examples each should have its own directory.
  *
  * > Running module examples uses a local state file.
  * > If you delete the .terraform directory the resources
  * > will be orphaned.
*/

locals {
  name               = terraform.workspace
  domain_name        = "bananalab.dev"
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)
  asg_min_instances  = length(local.availability_zones)
}

provider "aws" {
  default_tags {
    tags = {
      terraformed = "true"
      example     = "simple"
      module      = "bananalab-platform"
    }
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "this" {
  source             = "../../"
  name               = local.name
  availability_zones = local.availability_zones
  domain_name        = local.domain_name
  asg_min_instances  = local.asg_min_instances
  boot_script        = templatefile("${path.module}/boot_script.sh.tftpl", {})
}

output "result" {
  description = <<-EOT
    The result of the module.
  EOT
  value       = module.this.result
}
