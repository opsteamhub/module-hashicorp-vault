locals {
  task_definition_vault = templatefile(
    ".terraform/modules/hashicorp-vault/templates/task_definition_vault.json.tpl",
    {
      #image_vault    = "${var.aws_account}.dkr.ecr.${var.region_principal}.amazonaws.com/vault:15"
      image_vault    = join(".", [var.aws_account, "dkr.ecr", var.region_principal, "amazonaws.com/${var.vault_image}"])
      disable_mlock  = var.disable_mlock
      kms_id         = aws_kms_key.vault.key_id
      seal_type      = var.seal_type
      cpu            = var.cpu
      memory         = var.memory
      awslogs_group  = local.log_name
      region         = var.region_principal
      dynamodb_table = aws_dynamodb_table.dynamodb_table.name
      vault_addr     = aws_route53_record.vault_principal.fqdn
      ha_enabled     = var.ha_enabled

  })

  task_definition_vault_replica = templatefile(
    ".terraform/modules/hashicorp-vault/templates/task_definition_vault.json.tpl",
    {
      #image_vault    = "${var.aws_account}.dkr.ecr.${var.region_replica}.amazonaws.com/vault:15"
      image_vault    = join(".", [var.aws_account, "dkr.ecr", var.region_replica, "amazonaws.com/${var.vault_image}"])
      disable_mlock  = var.disable_mlock
      kms_id         = aws_kms_key.vault.key_id
      seal_type      = var.seal_type
      cpu            = var.cpu
      memory         = var.memory
      awslogs_group  = local.log_name
      region         = var.region_replica
      dynamodb_table = var.create_replica == true ? aws_dynamodb_table.dynamodb_table_replica[0].name : "not"
      vault_addr     = aws_route53_record.vault_replica[0].fqdn
      ha_enabled     = var.ha_enabled

  })
}

resource "aws_ecs_task_definition" "task_definition_vault" {
  family                = join("-", ["task-definition", local.vault_name])
  container_definitions = local.task_definition_vault
  task_role_arn         = aws_iam_role.task_vault.arn

  tags = {
    ProvisionedBy = local.provisioner
    Squad         = local.squad
    Service       = local.service
  }
  volume {
    name      = "vault-logs"
    host_path = "/mnt/vault/logs"
  }
}

###

resource "aws_ecs_task_definition" "task_definition_vault_replica" {
  count                 = var.create_replica ? 1 : 0
  provider              = aws.replica
  family                = join("-", ["task-definition", local.vault_name])
  container_definitions = local.task_definition_vault_replica
  task_role_arn         = aws_iam_role.task_vault_replica[0].arn

  tags = {
    ProvisionedBy = local.provisioner
    Squad         = local.squad
    Service       = local.service
  }
  volume {
    name      = "vault-logs"
    host_path = "/mnt/vault/logs"
  }
}

