# empire-stack

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

<!-- This will become the header in README.md
     Add a description of the module here.
     Do not include Variable or Output descriptions. -->

## Example

```hcl
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
```
<!-- markdownlint-disable -->

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_alb"></a> [alb](#module\_alb) | ../aws-https-alb | n/a |
| <a name="module_asg"></a> [asg](#module\_asg) | ../aws-ec2-asg | n/a |
| <a name="module_ecs"></a> [ecs](#module\_ecs) | ../aws-ecs-cluster | n/a |
| <a name="module_log_bucket"></a> [log\_bucket](#module\_log\_bucket) | ../aws-s3-bucket | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | ../aws-vpc | n/a |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~>5.0 |

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~>1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~>5.0 |

## Resources

| Name | Type |
|------|------|
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_availability_zones"></a> [availability\_zones](#input\_availability\_zones) | Availability zones to create resources in. | `list(string)` | n/a | yes |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Name of existing Route53 domain to use. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | The name of the resources created by this module.<br>This value is used as the basis for naming various resources. | `string` | n/a | yes |
| <a name="input_asg_instance_type"></a> [asg\_instance\_type](#input\_asg\_instance\_type) | EC2 instance type to use in the autoscaling group. | `string` | `"m6i.4xlarge"` | no |
| <a name="input_asg_max_instances"></a> [asg\_max\_instances](#input\_asg\_max\_instances) | Maximum number of instances in the autoscaling group.  If this is less than<br>`asg_min_instances` then `asg_min_instances` will be used. | `number` | `1` | no |
| <a name="input_asg_min_instances"></a> [asg\_min\_instances](#input\_asg\_min\_instances) | Minimum number of instances in the autoscaling group. | `number` | `1` | no |
| <a name="input_asg_root_volume_size"></a> [asg\_root\_volume\_size](#input\_asg\_root\_volume\_size) | Size in GB of root volume. | `number` | `1000` | no |
| <a name="input_boot_script"></a> [boot\_script](#input\_boot\_script) | Content of shell script to execute at EC2 boot.<br>Do not include plain text secrets. | `string` | `null` | no |
| <a name="input_ecs_agent_config"></a> [ecs\_agent\_config](#input\_ecs\_agent\_config) | Key / Value pairs of ECS Agent environment variables.<br>See: https://github.com/aws/amazon-ecs-agent/blob/master/README.md#environment-variables<br>For options.<br>ECS\_CLUSTER is set by default. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_result"></a> [result](#output\_result) | The result of the module. |


<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
