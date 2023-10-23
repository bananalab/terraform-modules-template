/**
  * <!-- This will become the header in README.md
  *      Add a description of the module here.
  *      Do not include Variable or Output descriptions. -->
*/

locals {
  fqdn = "${var.application_host}.${var.domain_name}"
}

resource "aws_security_group" "alb" {
  # checkov:skip=CKV_AWS_260: N/A
  name        = "${var.name}-allow_web_ports"
  description = "Allow web ports"
  vpc_id      = var.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  # checkov:skip=CKV_AWS_260: N/A
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from public"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from public"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "intragroup" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Allow intragroup"
  ip_protocol                  = "-1"
  referenced_security_group_id = aws_security_group.alb.id
}

resource "aws_vpc_security_group_egress_rule" "allow_all" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow egress"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_lb" "this" {
  # checkov:skip=CKV_AWS_150: N/A
  # checkov:skip=CKV2_AWS_28: Deletion protection isn't desired here
  name                       = var.name
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb.id]
  subnets                    = var.subnet_ids
  drop_invalid_header_fields = true
  enable_deletion_protection = false
  idle_timeout               = var.idle_timeout

  access_logs {
    bucket  = var.log_bucket
    prefix  = "${var.name}/alb"
    enabled = true
  }
}

resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.id
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate_validation.this.certificate_arn
  ssl_policy        = "ELBSecurityPolicy-FS-1-2-Res-2020-10"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/html"
      message_body = "Not Found."
      status_code  = "404"
    }
  }

  lifecycle {
    replace_triggered_by = [aws_acm_certificate.this]
  }
}

data "aws_route53_zone" "this" {
  name = var.domain_name
}

resource "aws_route53_record" "alb" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = local.fqdn
  type    = "A"

  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = true
  }
}

resource "aws_acm_certificate" "this" {
  domain_name       = local.fqdn
  validation_method = "DNS"

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
  zone_id         = data.aws_route53_zone.this.zone_id
}

resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for record in aws_route53_record.validation : record.fqdn]
}
/*
module "log_bucket" {
  source             = "../aws-s3-bucket"
  bucket_prefix      = "${var.name}-lb-logs"
  enable_replication = false
  logging_enabled    = false
}
*/
data "aws_iam_policy_document" "log_access" {
  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["arn:aws:s3:::${var.log_bucket}/*"]
    actions   = ["s3:PutObject"]

    principals {
      type = "AWS"
      # TODO: Allow other regions
      # See: https://docs.aws.amazon.com/elasticloadbalancing/latest/application/enable-access-logging.html#attach-bucket-policy
      identifiers = [
        "arn:aws:iam::027434742980:root", # us-west-1
        "arn:aws:iam::797873946194:root"  # us-west-2
      ]
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = var.log_bucket
  policy = data.aws_iam_policy_document.log_access.json
}
