resource "aws_security_group" "aurora_db_sg" {
  name        = var.db_sg_name
  description = "Aurora DB Security Group enabling PostgreSQL connections"
  vpc_id      = data.aws_vpc.vpc.id

  tags = {
    Name = var.db_sg_name
  }
}

resource "aws_security_group_rule" "auroradb_self_ingress" {
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  self              = true
  security_group_id = aws_security_group.aurora_db_sg.id
}

resource "aws_security_group_rule" "auroradb_subnet_ingress" {
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  cidr_blocks       = data.aws_subnet.subnets.*.cidr_block
  security_group_id = aws_security_group.aurora_db_sg.id
}
