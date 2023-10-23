/**
  * <!-- This will become the header in README.md
  *      Add a description of the module here.
  *      Do not include Variable or Output descriptions. -->
*/

locals {
  fqdn         = var.fqdn
  domain_parts = split(".", local.fqdn)
  domain       = length(local.domain_parts) == 2 ? var.fqdn : join(".", slice(split(".", local.fqdn), 1, length(split(".", local.fqdn))))
  vpc_id       = data.aws_subnet.this.vpc_id
}

resource "aws_ecs_task_definition" "this" {
  family                   = var.name
  container_definitions    = var.container_definitions
  task_role_arn            = var.task_role_arn
  execution_role_arn       = aws_iam_role.ecs_execution.arn
  network_mode             = "awsvpc"
  cpu                      = var.cpu
  memory                   = var.memory
  requires_compatibilities = var.requires_compatibilities
  tags                     = var.task_tags
  dynamic "placement_constraints" {
    for_each = var.placement_constraints
    content {
      type       = placement_constraints.value.type
      expression = lookup(placement_constraints.value.expression, null)
    }
  }

  dynamic "volume" {
    # TODO: Support EFS volumes
    for_each = var.volumes
    content {
      name = volume.key
      docker_volume_configuration {
        scope         = lookup(volume.value.docker_volume_configuration, "scope", null)
        autoprovision = lookup(volume.value.docker_volume_configuration, "autoprovision", null)
        driver        = lookup(volume.value.docker_volume_configuration, "driver", null)
        driver_opts   = lookup(volume.value.docker_volume_configuration, "driver_opts", null)
        labels        = lookup(volume.value.docker_volume_configuration, "labels", null)
      }
    }
  }
}

resource "aws_ecs_service" "this" {
  name            = var.name
  cluster         = var.ecs_cluster_id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  capacity_provider_strategy {
    base              = 1
    capacity_provider = var.capacity_provider
    weight            = 100
  }
  network_configuration {
    subnets          = var.subnet_ids
    assign_public_ip = false
    security_groups  = [aws_security_group.service.id]
  }

  dynamic "load_balancer" {
    for_each = var.load_balancer_targets
    content {
      target_group_arn = aws_lb_target_group.this[load_balancer.key].arn
      container_port   = lookup(load_balancer.value, "port", 80)
      container_name   = load_balancer.key
    }
  }
}

data "aws_subnet" "this" {
  id = var.subnet_ids[0]
}

resource "aws_lb_target_group" "this" {
  # checkov:skip=CKV_AWS_261
  for_each    = var.load_balancer_targets
  port        = lookup(each.value, "port", 80)
  protocol    = lookup(each.value, "protocol", "HTTP")
  target_type = "ip"
  vpc_id      = local.vpc_id
}

data "aws_lb_listener" "selected443" {
  load_balancer_arn = var.load_balancer_arn
  port              = 443
}

data "aws_route53_zone" "selected" {
  name         = local.domain
  private_zone = false
}

data "aws_lb" "this" {
  arn = var.load_balancer_arn
}

resource "aws_acm_certificate" "this" {
  domain_name               = local.fqdn
  validation_method         = "DNS"
  subject_alternative_names = keys(var.url_rewrites)

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "validation" {
  for_each = {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.selected.zone_id
}

resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]
}

resource "aws_lb_listener_certificate" "this" {
  listener_arn    = data.aws_lb_listener.selected443.arn
  certificate_arn = aws_acm_certificate_validation.this.certificate_arn
}

resource "aws_route53_record" "this" {
  for_each = toset(concat([var.fqdn], keys(var.url_rewrites)))
  zone_id  = data.aws_route53_zone.selected.zone_id
  name     = each.value
  type     = "A"
  alias {
    name                   = data.aws_lb.this.dns_name
    zone_id                = data.aws_lb.this.zone_id
    evaluate_target_health = true
  }
  weighted_routing_policy {
    weight = var.dns_routing_weight
  }
  set_identifier = "${var.name}-${each.value}"
}

resource "aws_lb_listener_rule" "this" {
  for_each     = aws_lb_target_group.this
  listener_arn = data.aws_lb_listener.selected443.arn

  action {
    type             = "forward"
    target_group_arn = each.value.arn
  }

  condition {
    host_header {
      values = [var.fqdn]
    }
  }
}

resource "aws_lb_listener_rule" "rewrite" {
  for_each     = var.url_rewrites
  listener_arn = data.aws_lb_listener.selected443.arn

  action {
    type = "redirect"
    redirect {
      host        = lookup(each.value, "host", var.fqdn)
      path        = lookup(each.value, "path", "")
      query       = lookup(each.value, "query", "")
      status_code = "HTTP_301"
    }
  }

  condition {
    host_header {
      values = [each.key]
    }
  }
}

resource "aws_security_group" "service" {
  name        = "${var.name}_allow_lb_traffic"
  description = "Allow LB traffic"
  vpc_id      = local.vpc_id

  dynamic "ingress" {
    for_each = var.load_balancer_targets
    content {
      description     = "Allow service traffic"
      from_port       = lookup(ingress.value, "port", 80)
      to_port         = lookup(ingress.value, "port", 80)
      protocol        = "tcp"
      security_groups = data.aws_lb.this.security_groups
    }
  }

  egress {
    description      = "Allow all."
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

data "aws_iam_policy_document" "ecs_execution_policy" {
  # checkov:skip=CKV_AWS_356
  # checkov:skip=CKV_AWS_111
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:CreateLogGroup"
    ]

    resources = [
      "*"
    ]
  }
}

resource "aws_iam_policy" "ecs_execution" {
  name   = "${var.name}_default_ecs_execution_policy"
  path   = "/"
  policy = data.aws_iam_policy_document.ecs_execution_policy.json
}

data "aws_iam_policy_document" "ecs_execution_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_execution" {
  name               = "${var.name}EcsExecutionRole"
  path               = "/system/"
  assume_role_policy = data.aws_iam_policy_document.ecs_execution_role_policy.json
}

resource "aws_iam_role_policy_attachment" "ecs_task" {
  role       = aws_iam_role.ecs_execution.name
  policy_arn = aws_iam_policy.ecs_execution.arn
}
