/**
  * <!-- This will become the header in README.md
  *      Add a description of the module here.
  *      Do not include Variable or Output descriptions. -->
  */

locals {
  name              = var.name
  ami_id            = var.ami_id != null ? var.ami_id : jsondecode(data.aws_ssm_parameter.ami_id[0].value)["image_id"]
  user_data_b64     = var.user_data == null ? null : base64encode(var.user_data)
  subnet_ids        = var.subnet_ids
  cloudwatch_config = var.cloudwatch_config != null ? var.cloudwatch_config : templatefile("${path.module}/cloudwatch-config.tftpl", { autoscaling_group_name = aws_autoscaling_group.this.name })
}

data "aws_ssm_parameter" "ami_id" {
  count = var.ami_id == null ? 1 : 0
  name  = var.ami_ssm_parameter
}

data "aws_iam_policy_document" "this" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "${local.name}-InstanceProfile"
  path               = "/system/"
  assume_role_policy = data.aws_iam_policy_document.this.json
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each   = toset(var.instance_role_policies)
  role       = aws_iam_role.this.name
  policy_arn = each.value
}

resource "aws_iam_instance_profile" "this" {
  role = aws_iam_role.this.name
}

resource "aws_launch_template" "this" {
  #checkov:skip=CKV_AWS_46:N/A
  image_id      = local.ami_id
  instance_type = var.instance_type
  name          = local.name
  user_data     = local.user_data_b64

  vpc_security_group_ids = var.security_group_ids

  iam_instance_profile {
    arn = aws_iam_instance_profile.this.arn
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = var.root_volume_size
    }
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
}

resource "aws_ssm_association" "configure_aws_packages" {
  for_each            = toset(var.aws_packages)
  name                = "AWS-ConfigureAWSPackage"
  schedule_expression = "cron(0 2 ? * SUN *)"
  targets {
    key = "tag:aws:autoscaling:groupName"
    values = [
      aws_autoscaling_group.this.name
    ]
  }
  parameters = {
    "action" = "Install"
    "name"   = each.value
  }
}

resource "aws_ssm_parameter" "cloudwatch_config" {
  #checkov:skip=CKV_AWS_337: TODO: Ensure SSM parameters are using KMS CMK.
  name  = "/${local.name}/cloudwatch-config"
  type  = "SecureString"
  value = local.cloudwatch_config
}

resource "aws_ssm_association" "cloudwatch_manage_agent" {
  # TODO: This tries to apply before the Cloudwatch Agent is installed
  #       so it fails.  It works at the next 30 minute interval but that
  #       leaves a 30 minute gap every time a new instance launches.
  count               = contains(var.aws_packages, "AmazonCloudWatchAgent") ? 1 : 0
  name                = "AmazonCloudWatch-ManageAgent"
  schedule_expression = "rate(30 minutes)"
  targets {
    key = "tag:aws:autoscaling:groupName"
    values = [
      aws_autoscaling_group.this.name
    ]
  }
  parameters = {
    "optionalConfigurationLocation" = aws_ssm_parameter.cloudwatch_config.name
  }
}

resource "aws_autoscaling_group" "this" {
  name                  = local.name
  max_size              = var.max_size
  min_size              = var.min_size
  vpc_zone_identifier   = local.subnet_ids
  target_group_arns     = var.target_group_arns
  protect_from_scale_in = false

  launch_template {
    id      = aws_launch_template.this.id
    version = aws_launch_template.this.latest_version
  }

  dynamic "tag" {
    for_each = var.instance_tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  tag {
    key                 = "Name"
    value               = local.name
    propagate_at_launch = true
  }
}
