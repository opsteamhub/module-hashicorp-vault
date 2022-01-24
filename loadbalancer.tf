resource "aws_lb_target_group" "tg_vault" {
  name     = join("-", ["tg", local.vault_name])
  port     = 8200
  protocol = "TCP"
  vpc_id   = data.aws_vpc.vpc_selected.id

  health_check {
    port     = 8200
    protocol = "TCP"
  }

  tags = {
    Name          = join("-", ["tg", local.vault_name])
    ProvisionedBy = local.provisioner
    Squad         = local.squad
    Service       = local.service
  }
}

resource "aws_lb" "elb_vault" {
  name               = join("-", ["lb", local.vault_name])
  internal           = var.private_vault
  load_balancer_type = "network"
  subnets            = data.aws_subnet_ids.public.ids

  enable_deletion_protection = false

  tags = {
    Name          = join("-", ["lb", local.vault_name])
    ProvisionedBy = local.provisioner
    Squad         = local.squad
    Service       = local.service
  }
}

resource "aws_lb_listener" "listener_vault" {
  load_balancer_arn = aws_lb.elb_vault.arn
  port              = "443"
  protocol          = "TLS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.issued.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_vault.arn
  }
}

###

resource "aws_lb_target_group" "tg_vault_replica" {
  provider = aws.replica
  name     = join("-", ["tg", local.vault_name])
  port     = 8200
  protocol = "TCP"
  vpc_id   = aws_vpc.vpc_replica.id

  health_check {
    port     = 8200
    protocol = "TCP"
  }

  tags = {
    Name          = join("-", ["tg", local.vault_name])
    ProvisionedBy = local.provisioner
    Squad         = local.squad
    Service       = local.service
  }
}

resource "aws_lb" "elb_vault_replica" {
  provider           = aws.replica
  name               = join("-", ["lb", local.vault_name])
  internal           = var.private_vault
  load_balancer_type = "network"
  subnets            = [aws_subnet.pub_subnet_a_replica.id, aws_subnet.pub_subnet_b_replica.id]

  enable_deletion_protection = false

  tags = {
    Name          = join("-", ["lb", local.vault_name])
    ProvisionedBy = local.provisioner
    Squad         = local.squad
    Service       = local.service
  }
}

resource "aws_lb_listener" "listener_vault_replica" {
  provider          = aws.replica
  load_balancer_arn = aws_lb.elb_vault_replica.arn
  port              = "443"
  protocol          = "TLS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = data.aws_acm_certificate.issued_replica.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_vault_replica.arn
  }
}




































