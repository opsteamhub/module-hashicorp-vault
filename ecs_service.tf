resource "aws_ecs_service" "vault" {
  name            = join("-", ["service", local.vault_name])
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.task_definition_vault.arn
  desired_count   = var.desired_task_count

  tags = {
    ProvisionedBy = local.provisioner
    Squad         = local.squad
    Service       = local.service
  }
}

resource "aws_ecs_service" "vault_replica" {
  provider        = aws.replica
  name            = join("-", ["service", local.vault_name])
  cluster         = aws_ecs_cluster.ecs_cluster_replica.id
  task_definition = aws_ecs_task_definition.task_definition_vault_replica.arn
  desired_count   = var.desired_task_count

  tags = {
    ProvisionedBy = local.provisioner
    Squad         = local.squad
    Service       = local.service
  }
}

