locals {
  task_definition_vault = templatefile(
    "./module/templates/task_definition_vault.json.tpl",
    {
      #image_vault    = "${var.aws_account}.dkr.ecr.${var.region_principal}.amazonaws.com/vault:15"
      image_vault    = join(".", [var.aws_account, "dkr.ecr", var.region_principal, "amazonaws.com/vault:15"])
      disable_mlock  = var.disable_mlock
      kms_id         = aws_kms_key.vault.key_id
      seal_type      = var.seal_type
      cpu            = var.cpu
      memory         = var.memory
      awslogs_group  = local.log_name
      region         = var.region_principal
      dynamodb_table = aws_dynamodb_table.dynamodb_table.name

  })

  task_definition_vault_replica = templatefile(
    "./module/templates/task_definition_vault.json.tpl",
    {
      #image_vault    = "${var.aws_account}.dkr.ecr.${var.region_replica}.amazonaws.com/vault:15"
      image_vault    = join(".", [var.aws_account, "dkr.ecr", var.region_replica, "amazonaws.com/vault:15"])
      disable_mlock  = var.disable_mlock
      kms_id         = aws_kms_key.vault.key_id
      seal_type      = var.seal_type
      cpu            = var.cpu
      memory         = var.memory
      awslogs_group  = local.log_name
      region         = var.region_replica
      dynamodb_table = aws_dynamodb_table.dynamodb_table_replica.name

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

}

###

resource "aws_ecs_task_definition" "task_definition_vault_replica" {
  provider              = aws.replica
  family                = join("-", ["task-definition", local.vault_name])
  container_definitions = local.task_definition_vault_replica
  task_role_arn         = aws_iam_role.task_vault_replica.arn

  tags = {
    ProvisionedBy = local.provisioner
    Squad         = local.squad
    Service       = local.service
  }

}

