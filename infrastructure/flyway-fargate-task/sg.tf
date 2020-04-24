data "aws_vpc" "vpc" {
  tags = {
    Name = var.vpc_name
  }
}

resource "aws_security_group" "flyway_fargate_sg" {
  name        = "${var.task_sg_name}-${var.env}-${var.region}"
  description = "flyway fargate sg"
  vpc_id      = data.aws_vpc.vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.task_sg_name}-${var.env}-${var.region}"
  }
}
