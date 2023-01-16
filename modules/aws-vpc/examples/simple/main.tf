module "this" {
  source             = "../../"
  cidr               = "10.0.0.0/16"
  availability_zones = ["us-west-1b", "us-west-1c"]
  public_subnets     = ["10.0.0.0/20", "10.0.16.0/20"]
  private_subnets    = ["10.0.32.0/20", "10.0.48.0/20"]
}

output "result" {
  description = <<-EOT
    The result of the module.
  EOT
  value       = module.this.result
}
