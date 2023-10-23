/**
  * <!-- This will become the header in README.md
  *      Add a description of the module here.
  *      Do not include Variable or Output descriptions. -->
*/

locals {
  name             = var.name
  ecs_agent_config = <<-EOT
  %{for k, v in merge({ ECS_CLUSTER = local.name }, var.ecs_agent_config)~}
  ${upper(k)}=${v}
  %{endfor~}
  EOT

  user_data_yaml = yamlencode(
    {
      write_files = [
        {
          path    = "/etc/ecs/ecs.config"
          content = local.ecs_agent_config
        }
      ],
      runcmd = [
        var.boot_script
      ]
    }
  )
  user_data = "#cloud-config\n${local.user_data_yaml}"
}

data "aws_caller_identity" "current" {}

module "vpc" {
  source                 = "../aws-vpc"
  name                   = var.name
  availability_zones     = var.availability_zones
  vpc_ip_address         = "10.11.0.0"
  vpc_netmask_length     = 16
  subnets_netmask_length = 20
  create_public_subnets  = true
  create_nat_gateways    = true
}

module "asg" {
  source            = "../aws-ec2-asg"
  name              = local.name
  subnet_ids        = [for subnet in module.vpc.result.private_subnets : subnet.id]
  instance_type     = var.asg_instance_type
  ami_ssm_parameter = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended"
  max_size          = max(var.asg_max_instances, var.asg_min_instances)
  min_size          = var.asg_min_instances
  root_volume_size  = var.asg_root_volume_size
  instance_role_policies = [
    "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role",
    "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
    "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
  ]
  user_data = local.user_data
  instance_tags = {
    AmazonECSManaged = true
  }
}

module "alb" {
  source           = "../aws-https-alb"
  name             = local.name
  vpc_id           = module.vpc.result.vpc.id
  subnet_ids       = [for subnet in module.vpc.result.public_subnets : subnet.id]
  application_host = local.name
  domain_name      = var.domain_name
  log_bucket       = module.log_bucket.result.bucket.bucket
}

module "ecs" {
  source                = "../aws-ecs-cluster"
  name                  = local.name
  autoscaling_group_arn = module.asg.result.autoscaling_group.arn
}

module "log_bucket" {
  source             = "../aws-s3-bucket"
  bucket             = "${local.name}-${data.aws_caller_identity.current.account_id}"
  logging_enabled    = false
  enable_replication = false
}
