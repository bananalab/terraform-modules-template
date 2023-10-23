resource "aws_wafv2_web_acl" "this" {
  #checkov:skip=CKV2_AWS_31:False positive.
  #checkov:skip=CKV_AWS_192:N/A
  count = var.enable_waf ? 1 : 0
  name  = var.name
  scope = "REGIONAL"

  default_action {
    allow {
    }
  }
  dynamic "rule" {
    for_each = var.waf_managed_rules
    content {
      name     = "AWS-${rule.key}"
      priority = index(keys(var.waf_managed_rules), rule.key)
      override_action {
        none {}
      }
      statement {
        managed_rule_group_statement {
          name        = rule.key
          vendor_name = "AWS"
          dynamic "rule_action_override" {
            for_each = lookup(rule.value, "rule_action_overrides", {})
            content {
              name = rule_action_override.key
              action_to_use {
                allow {

                }
              }
            }
          }
        }
      }
      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = "AWS-${rule.key}"
        sampled_requests_enabled   = true
      }
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = var.name
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_web_acl_association" "this" {
  count        = var.enable_waf ? 1 : 0
  web_acl_arn  = aws_wafv2_web_acl.this[0].arn
  resource_arn = aws_lb.this.arn
}

resource "aws_cloudwatch_log_group" "this" {
  #checkov:skip=CKV_AWS_158: TODO: Enable KMS
  #checkov:skip=CKV_AWS_338: TODO: Set retention
  count             = var.enable_waf ? 1 : 0
  name              = "aws-waf-logs-${aws_wafv2_web_acl.this[0].name}"
  retention_in_days = var.waf_log_retention_days
}

resource "aws_wafv2_web_acl_logging_configuration" "this" {
  count                   = var.enable_waf ? 1 : 0
  log_destination_configs = [aws_cloudwatch_log_group.this[0].arn]
  resource_arn            = aws_wafv2_web_acl.this[0].arn
}
