variable "name" {
  default = "aws-https-module-example"
}

variable "domain_name" {
  default = "bananalab.dev"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

module "this" {
  source           = "../../"
  name             = var.name
  vpc_id           = data.aws_vpc.default.id
  subnet_ids       = data.aws_subnets.default.ids
  application_host = var.name
  domain_name      = var.domain_name
}

output "result" {
  description = <<-EOT
    The result of the module.
  EOT
  value       = module.this.result
}
