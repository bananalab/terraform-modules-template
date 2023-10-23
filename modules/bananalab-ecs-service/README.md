# empire-ecs-service

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
```
<!-- markdownlint-disable -->

## Modules

No modules.

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
| [aws_acm_certificate.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource |
| [aws_acm_certificate_validation.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation) | resource |
| [aws_ecs_service.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_task_definition.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_iam_policy.ecs_execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_role.ecs_execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.ecs_task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lb_listener_certificate.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_certificate) | resource |
| [aws_lb_listener_rule.rewrite](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule) | resource |
| [aws_lb_listener_rule.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule) | resource |
| [aws_lb_target_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |
| [aws_route53_record.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.validation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_security_group.service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_iam_policy_document.ecs_execution_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ecs_execution_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_lb.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/lb) | data source |
| [aws_lb_listener.selected443](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/lb_listener) | data source |
| [aws_route53_zone.selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |
| [aws_subnet.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_capacity_provider"></a> [capacity\_provider](#input\_capacity\_provider) | ECS Capacity Provider to use. | `string` | n/a | yes |
| <a name="input_container_definitions"></a> [container\_definitions](#input\_container\_definitions) | A valid JSON document describing valid container definitions.<br>See: http://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_ContainerDefinition.html | `string` | n/a | yes |
| <a name="input_ecs_cluster_id"></a> [ecs\_cluster\_id](#input\_ecs\_cluster\_id) | ECS Cluster to deploy to. | `string` | n/a | yes |
| <a name="input_fqdn"></a> [fqdn](#input\_fqdn) | Fully qualified domain name of load balanced service. | `string` | n/a | yes |
| <a name="input_load_balancer_arn"></a> [load\_balancer\_arn](#input\_load\_balancer\_arn) | ARN of the loadbalancer to associate services with. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | The name of the resources created by this module.<br>This value is used as the basis for naming various resources. | `string` | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | Subnets associated with the task or service. | `list(string)` | n/a | yes |
| <a name="input_cpu"></a> [cpu](#input\_cpu) | The number of cpu units used by the task. If the `requires_compatibilities`<br>is "FARGATE" this field is required. | `number` | `null` | no |
| <a name="input_desired_count"></a> [desired\_count](#input\_desired\_count) | The number of service replicas. | `number` | `2` | no |
| <a name="input_dns_routing_weight"></a> [dns\_routing\_weight](#input\_dns\_routing\_weight) | The weight can be a number between 0 and 255. If you specify 0, Route 53<br>stops responding to DNS queries using this record. | `number` | `255` | no |
| <a name="input_load_balancer_targets"></a> [load\_balancer\_targets](#input\_load\_balancer\_targets) | Load balancer target configs. | `map(any)` | `null` | no |
| <a name="input_memory"></a> [memory](#input\_memory) | The amount (in MiB) of memory used by the task. If the<br>`requires_compatibilities` is "FARGATE" this field is required. | `number` | `null` | no |
| <a name="input_placement_constraints"></a> [placement\_constraints](#input\_placement\_constraints) | Configuration block for rules that are taken into consideration during task<br>placement. Maximum number of `placement_constraints` is 10. | `map(any)` | `{}` | no |
| <a name="input_requires_compatibilities"></a> [requires\_compatibilities](#input\_requires\_compatibilities) | Set of launch types required by the task. The valid values are EC2 and<br>FARGATE. | `list(string)` | `null` | no |
| <a name="input_task_role_arn"></a> [task\_role\_arn](#input\_task\_role\_arn) | The ARN of IAM role that allows your Amazon ECS container task to make<br>calls to other AWS services. | `string` | `null` | no |
| <a name="input_task_tags"></a> [task\_tags](#input\_task\_tags) | Key-value map of resource tags. | `map(string)` | `null` | no |
| <a name="input_url_rewrites"></a> [url\_rewrites](#input\_url\_rewrites) | A mapping of fqdns and rewrite rules.<br>e.x.:<br>  {<br>    foo.dev-empire.com = "https://www.empi.re/listen/index.php?id=$1"<br>  } | `map(any)` | `{}` | no |
| <a name="input_volumes"></a> [volumes](#input\_volumes) | List of volume configurations. | `map(any)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_result"></a> [result](#output\_result) | The result of the module. |


<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
