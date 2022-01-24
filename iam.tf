locals {
  policy_vault = templatefile(
    "./module/templates/task_policy.json.tpl",
    {
      kms_resource      = aws_kms_key.vault.arn
      dynamodb_resource = aws_dynamodb_table.dynamodb_table.arn
  })

  policy_vault_replica = templatefile(
    "./module/templates/task_policy_replica.json.tpl",
    {
      kms_resource_replica      = aws_kms_replica_key.replica.arn
      dynamodb_resource_replica = aws_dynamodb_table.dynamodb_table_replica.arn
  })
}

data "aws_iam_policy_document" "ecs_agent" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}
data "aws_iam_policy_document" "task_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "policy_vault" {
  name   = join("-", ["policy", local.vault_name])
  role   = aws_iam_role.task_vault.id
  policy = local.policy_vault
}
resource "aws_iam_role" "ecs_agent" {
  name               = join("-", ["role-ec2", local.vault_name])
  assume_role_policy = data.aws_iam_policy_document.ecs_agent.json

  tags = {
    ProvisionedBy = local.provisioner
    Squad         = local.squad
    Service       = local.service
  }
}
resource "aws_iam_role" "task_vault" {
  name               = join("-", ["role-task", local.vault_name])
  assume_role_policy = data.aws_iam_policy_document.task_role.json

  tags = {
    ProvisionedBy = local.provisioner
    Squad         = local.squad
    Service       = local.service
  }
}

resource "aws_iam_role_policy_attachment" "ecs_agent" {
  role       = aws_iam_role.ecs_agent.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}
resource "aws_iam_instance_profile" "ecs_agent" {
  name = join("-", ["instance-profile", local.vault_name])
  role = aws_iam_role.ecs_agent.name
}

###

data "aws_iam_policy_document" "ecs_agent_replica" {
  provider = aws.replica
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}
data "aws_iam_policy_document" "task_role_replica" {
  provider = aws.replica
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "policy_vault_replica" {
  provider = aws.replica
  name     = join("-", ["policy", local.vault_name])
  role     = aws_iam_role.task_vault_replica.id
  policy   = local.policy_vault_replica
}

resource "aws_iam_role" "ecs_agent_replica" {
  provider           = aws.replica
  name               = join("-", ["role-ec2", local.vault_name, "replica"])
  assume_role_policy = data.aws_iam_policy_document.ecs_agent_replica.json

  tags = {
    ProvisionedBy = local.provisioner
    Squad         = local.squad
    Service       = local.service
  }
}

resource "aws_iam_role" "task_vault_replica" {
  provider           = aws.replica
  name               = join("-", ["role-task", local.vault_name, "replica"])
  assume_role_policy = data.aws_iam_policy_document.task_role_replica.json

  tags = {
    ProvisionedBy = local.provisioner
    Squad         = local.squad
    Service       = local.service
  }
}

resource "aws_iam_role_policy_attachment" "ecs_agent_replica" {
  provider   = aws.replica
  role       = aws_iam_role.ecs_agent_replica.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_agent_replica" {
  provider = aws.replica
  name     = join("-", ["instance-profile", local.vault_name, "replica"])
  role     = aws_iam_role.ecs_agent_replica.name
}