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
