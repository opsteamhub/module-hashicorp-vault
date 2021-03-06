resource "aws_kms_key" "vault" {
  description             = "Vault unseal key"
  deletion_window_in_days = 7
  multi_region            = true

  tags = {
    Name          = "${local.vault_name}-vault-kms-unseal-key"
    ProvisionedBy = local.provisioner
    Squad         = local.squad
    Service       = local.service
  }
}

resource "aws_kms_alias" "vault" {
  name          = "alias/${local.vault_name}-vault-kms-unseal-key"
  target_key_id = aws_kms_key.vault.key_id
}

####

resource "aws_kms_alias" "vault_replica" {
  count         = var.create_replica ? 1 : 0
  provider      = aws.replica
  name          = "alias/${local.vault_name}-vault-kms-unseal-key"
  target_key_id = aws_kms_replica_key.replica[0].arn
}

resource "aws_kms_replica_key" "replica" {
  count                   = var.create_replica ? 1 : 0
  provider                = aws.replica
  description             = "Multi-Region replica key"
  deletion_window_in_days = 7
  primary_key_arn         = aws_kms_key.vault.arn
}
