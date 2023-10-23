output "result" {
  description = <<-EOT
      The result of the module.
    EOT
  value = {
    vpc                  = aws_vpc.this
    public_subnets       = aws_subnet.public
    private_subnets      = aws_subnet.private
    public_route_table   = try(aws_route_table.public[0], null)
    private_route_tables = aws_route_table.private
  }
}
