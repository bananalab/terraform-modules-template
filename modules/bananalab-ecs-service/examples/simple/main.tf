/**
  * Examples should illustrate typical use cases.
  * For multiple examples each should have its own directory.
  *
  * > Running module examples uses a local state file.
  * > If you delete the .terraform directory the resources
  * > will be orphaned.
*/

provider "aws" {
  default_tags {
    tags = {
      terraformed = "true"
      example     = "simple"
      module      = local.name
    }
  }
}

data "aws_vpc" "this" {
  tags = {
    Name = local.platform_id
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.this.id]
  }

  tags = {
    Tier = "Private"
  }
}

data "aws_ecs_cluster" "this" {
  cluster_name = local.platform_id
}

data "aws_lb" "this" {
  name = local.platform_id
}

locals {
  name                  = "bananalab-ecs-service-example"
  domain_name           = "bananalab.dev"
  platform_id           = "default"
  container_definitions = file("container-definitions.json")
  volumes               = {}

  load_balancer_targets = {
    "nginx" = { port = 80 }
  }

  url_rewrites = {}

}

module "this" {
  source                = "../../"
  name                  = local.name
  fqdn                  = "${local.name}.${local.domain_name}"
  ecs_cluster_id        = data.aws_ecs_cluster.this.id
  capacity_provider     = local.platform_id
  subnet_ids            = data.aws_subnets.private.ids
  load_balancer_arn     = data.aws_lb.this.arn
  container_definitions = local.container_definitions
  volumes               = local.volumes
  load_balancer_targets = local.load_balancer_targets
  url_rewrites          = local.url_rewrites
}

output "result" {
  description = <<-EOT
    The result of the module.
  EOT
  value       = module.this.result
}
