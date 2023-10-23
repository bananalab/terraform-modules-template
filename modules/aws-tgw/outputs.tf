output "result" {
  description = <<-EOT
      The result of the module.
    EOT
  value = {
    transit_gateway = aws_ec2_transit_gateway.this
  }
}
