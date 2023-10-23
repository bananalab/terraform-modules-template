# aws-ec2-asg

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
      Name        = "asg-module-test"
    }
  }
}

data "aws_subnets" "private" {
  tags = {
    Tier = "Private"
  }
}

module "this" {
  source            = "../../"
  name              = "asg-module-example"
  user_data         = templatefile("user_data.sh", {})
  subnet_ids        = data.aws_subnets.private.ids
  ami_ssm_parameter = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended"
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
| <a name="requirement_random"></a> [random](#requirement\_random) | ~>3.0 |

## Resources

| Name | Type |
|------|------|
| [aws_autoscaling_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_iam_instance_profile.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_launch_template.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_ssm_association.cloudwatch_manage_agent](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_association) | resource |
| [aws_ssm_association.configure_aws_packages](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_association) | resource |
| [aws_ssm_parameter.cloudwatch_config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_parameter) | resource |
| [aws_iam_policy_document.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_ssm_parameter.ami_id](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_name"></a> [name](#input\_name) | The name of the ASG.<br>This value is used as the basis for naming various other resources.<br>If this value is not specified a random name will be generated. | `string` | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | Subnets to deploy instances in. | `list(string)` | n/a | yes |
| <a name="input_ami_id"></a> [ami\_id](#input\_ami\_id) | AMI ID for instances created by the ASG.<br>Conflicts with `ami_ssm_parameter`. | `string` | `null` | no |
| <a name="input_ami_ssm_parameter"></a> [ami\_ssm\_parameter](#input\_ami\_ssm\_parameter) | Name of SSM parameter that contains the AMI ID to use.<br>ex. "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended"<br>Conflicts with `ami_id`. | `string` | `null` | no |
| <a name="input_aws_packages"></a> [aws\_packages](#input\_aws\_packages) | List of AWS packages to deploy via SSM. | `list(string)` | <pre>[<br>  "AWSCodeDeployAgent",<br>  "AmazonCloudWatchAgent"<br>]</pre> | no |
| <a name="input_cloudwatch_config"></a> [cloudwatch\_config](#input\_cloudwatch\_config) | Cloudwatch config file contents. | `string` | `null` | no |
| <a name="input_instance_role_policies"></a> [instance\_role\_policies](#input\_instance\_role\_policies) | IAM Policy ARNs to attach to the instance profile. | `list(string)` | <pre>[<br>  "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforAWSCodeDeploy",<br>  "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",<br>  "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",<br>  "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",<br>  "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"<br>]</pre> | no |
| <a name="input_instance_tags"></a> [instance\_tags](#input\_instance\_tags) | Tags to apply to instances.<br>Use the provider `default_tags` feature for more consistent tagging. | `map(string)` | `{}` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | Instance type | `string` | `"t2.micro"` | no |
| <a name="input_max_size"></a> [max\_size](#input\_max\_size) | Maximum number of instances to create. | `number` | `1` | no |
| <a name="input_min_size"></a> [min\_size](#input\_min\_size) | Minimum number of instances to create. | `number` | `1` | no |
| <a name="input_root_volume_size"></a> [root\_volume\_size](#input\_root\_volume\_size) | Size in GB of root volume size. | `number` | `100` | no |
| <a name="input_security_group_ids"></a> [security\_group\_ids](#input\_security\_group\_ids) | Security groups to attach to the managed instances. | `list(string)` | `null` | no |
| <a name="input_target_group_arns"></a> [target\_group\_arns](#input\_target\_group\_arns) | Load balancer targets to register with. | `list(string)` | `null` | no |
| <a name="input_user_data"></a> [user\_data](#input\_user\_data) | Instance User Data.<br>See: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_result"></a> [result](#output\_result) | The result of the module. |


<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
