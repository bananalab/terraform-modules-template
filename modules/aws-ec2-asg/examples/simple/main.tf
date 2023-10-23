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
