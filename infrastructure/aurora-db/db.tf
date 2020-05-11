data "aws_security_group" "vpc_security_groups" {
  count  = length(var.security_group_names)
  vpc_id = data.aws_vpc.vpc.id

  tags = {
    Name = element(var.security_group_names, count.index)
  }
}

data "aws_secretsmanager_secret_version" "master_credentials" {
  secret_id = var.master_credentials_secret
}

resource "aws_db_subnet_group" "subnet_group" {
  name        = var.db_subnet_group_name
  subnet_ids  = data.aws_subnet.subnets.*.id
  description = "DB Subnet Group for Aurora Serverless PostgreSQL"
}

resource "aws_rds_cluster" "db" {
  cluster_identifier        = var.db_cluster_name
  engine                    = "aurora-postgresql"
  engine_mode               = "serverless"
  database_name             = var.db_name
  master_username           = jsondecode(data.aws_secretsmanager_secret_version.master_credentials.secret_string)["username"]
  master_password           = jsondecode(data.aws_secretsmanager_secret_version.master_credentials.secret_string)["password"]
  final_snapshot_identifier = "deleted-aurora-cluster"
  backup_retention_period   = 5
  preferred_backup_window   = "18:00-21:00"

  scaling_configuration {
    auto_pause               = true
    max_capacity             = 16
    min_capacity             = 2
    seconds_until_auto_pause = 300
    timeout_action           = "ForceApplyCapacityChange"
  }

  vpc_security_group_ids = concat(aws_security_group.aurora_db_sg.*.id, data.aws_security_group.vpc_security_groups.*.id)
  availability_zones     = var.availability_zones
  db_subnet_group_name   = aws_db_subnet_group.subnet_group.name
  enable_http_endpoint   = true
}
