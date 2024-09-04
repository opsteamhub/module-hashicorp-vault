# Security Group for NAT Instance
resource "aws_security_group" "sg-nat-instance" {
  count       = var.create_nat_instance ? 1 : 0
  name        = join("-", ["SG", "nat-instance", local.vault_name])
  description = "Security Group for NAT instance"
  vpc_id      = var.create_vpc == "false" ? var.vpc_id : aws_vpc.vpc[0].id
  tags = {
    "Name"          = join("-", ["SG", "nat-instance", local.vault_name])
    "ProvisionedBy" = local.provisioner
    "Squad"         = local.squad
    "Service"       = local.service
  }
}

# NAT Instance security group rule to allow all traffic from within the VPC
resource "aws_security_group_rule" "vpc-inbound" {
  count             = var.create_nat_instance ? 1 : 0
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.sg-nat-instance.id
}

# NAT Instance security group rule to allow outbound traffic
resource "aws_security_group_rule" "outbound-nat-instance" {
  count             = var.create_nat_instance ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
  security_group_id = aws_security_group.sg-nat-instance.id
}

# Get the latest NAT AMI
data "aws_ami" "natinstance_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn-ami-vpc-nat*"]
  }
}

# Create Network Interface
resource "aws_network_interface" "nat_instance_network_interface" {
  count             = var.create_nat_instance ? 1 : 0
  subnet_id         = aws_subnet.pub_subnet_b_principal[0].id
  security_groups   = [aws_security_group.sg-nat-instance.id]
  source_dest_check = false

  tags = {
    "Name"          = join("-", ["eni", "nat-instance", local.vault_name])
    "ProvisionedBy" = local.provisioner
    "Squad"         = local.squad
    "Service"       = local.service
  }
}

# Create Elastic IP
resource "aws_eip" "nat_instance_eip" {
  count = var.create_nat_instance ? 1 : 0
  vpc   = true

  tags = {
    "Name"          = join("-", ["eip", "nat-instance", local.vault_name])
    "ProvisionedBy" = local.provisioner
    "Squad"         = local.squad
    "Service"       = local.service
  }
}

# Associate Elastic IP with Network Interface
resource "aws_eip_association" "nat_instance_eip_assoc" {
  count                = var.create_nat_instance ? 1 : 0
  network_interface_id = aws_network_interface.nat_instance_network_interface[0].id
  allocation_id        = aws_eip.nat_instance_eip[0].id
}

# Launch Template for NAT Instance
resource "aws_launch_template" "nat_instance" {
  count       = var.create_nat_instance ? 1 : 0
  name_prefix = join("-", ["lt", "nat", local.vault_name])

  image_id      = data.aws_ami.natinstance_ami.id
  instance_type = "t3.medium"

  network_interfaces {
    device_index         = 0
    network_interface_id = aws_network_interface.nat_instance_network_interface[0].id
  }

  monitoring {
    enabled = false
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name          = join("-", ["nat-instance", local.vault_name])
      ProvisionedBy = local.provisioner
      Squad         = local.squad
      Service       = local.service
    }
  }
}

# Autoscaling Group for NAT Instance
resource "aws_autoscaling_group" "nat_asg_vault" {
  count               = var.create_nat_instance ? 1 : 0
  name_prefix         = join("-", ["asg", "nat-instance", local.vault_name])
  vpc_zone_identifier = [aws_subnet.pub_subnet_a_principal[0].id, aws_subnet.pub_subnet_b_principal[0].id]
  desired_capacity    = 1
  min_size            = 1
  max_size            = 1

  launch_template {
    id      = aws_launch_template.nat_instance[0].id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = join("-", ["asg", "nat-instance", local.vault_name])
    propagate_at_launch = true
  }

  tag {
    key                 = "ProvisionedBy"
    value               = local.provisioner
    propagate_at_launch = true
  }

  tag {
    key                 = "Squad"
    value               = local.squad
    propagate_at_launch = true
  }

  tag {
    key                 = "Service"
    value               = local.service
    propagate_at_launch = true
  }
}

# Network Interface Attachment to the Instance
resource "aws_network_interface_attachment" "nat_instance_attachment" {
  count                = var.create_nat_instance && length(aws_autoscaling_group.nat_asg_vault.instances) > 0 ? 1 : 0
  instance_id          = aws_autoscaling_group.nat_asg_vault.instances[0].instance_id
  network_interface_id = aws_network_interface.nat_instance_network_interface[0].id
  device_index         = 1
}
