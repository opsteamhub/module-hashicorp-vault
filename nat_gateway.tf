resource "aws_nat_gateway" "nat_gateway_pub_a_replica" {
  provider      = aws.replica
  allocation_id = aws_eip.eip_replica.id
  subnet_id     = aws_subnet.pub_subnet_a_replica.id

  tags = {
    Name          = join("-", ["ng", local.vault_name])
    ProvisionedBy = local.provisioner
    Squad         = local.squad
    Service       = local.service
  }
}
