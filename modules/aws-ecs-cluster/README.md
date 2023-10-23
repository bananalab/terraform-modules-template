# aws-ecs-cluster

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

<!-- This will become the header in README.md
     Add a description of the module here.
     Do not include Variable or Output descriptions. -->

## Example

```hcl
locals {
  name = "module-ecs-example"
}

provider "aws" {
  default_tags {
    tags = {
      Terraformed = true
      Environment = "test"
      Name        = local.name
    }
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  availability_zones = slice(data.aws_availability_zones.available.names, 0, 2)
}

module "vpc" {
  source                 = "../../../aws-vpc"
  name                   = local.name
  vpc_ip_address         = "10.97.0.0"
  vpc_netmask_length     = 16
  availability_zones     = local.availability_zones
  subnets_netmask_length = 20
  create_public_subnets  = true
  create_nat_gateways    = true
}

module "asg" {
  source            = "../../../aws-ec2-asg"
  name              = local.name
  subnet_ids        = [for subnet in module.vpc.result.private_subnets : subnet.id]
  ami_ssm_parameter = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended"
  instance_role_policies = [
    "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  ]
  user_data = templatefile("user_data.sh.tftpl", { name = local.name })
  instance_tags = {
    AmazonECSManaged = true
  }
}

module "this" {
  source                = "../.."
  name                  = local.name
  autoscaling_group_arn = module.asg.result.autoscaling_group.arn
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
| [aws_ecs_capacity_provider.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_capacity_provider) | resource |
| [aws_ecs_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster) | resource |
| [aws_ecs_cluster_capacity_providers.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_cluster_capacity_providers) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_autoscaling_group_arn"></a> [autoscaling\_group\_arn](#input\_autoscaling\_group\_arn) | ARN of autoscaling group to associate with the cluster. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Name of ECS Cluster and other resources. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_result"></a> [result](#output\_result) | The result of the module. |


<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
