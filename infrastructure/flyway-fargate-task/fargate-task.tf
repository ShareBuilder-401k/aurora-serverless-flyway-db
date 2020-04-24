data "aws_secretsmanager_secret" "registry_credentials" {
  name = var.registry_token
}

data "aws_rds_cluster" "auroradb_cluster" {
  cluster_identifier = "${var.auroradb_cluster_name}-${var.env}-${var.region}"
}

data "aws_iam_role" "task_role" {
  name = var.task_iam_role
}

data "template_file" "taskdef_template" {
  template = file("taskdef-template.json")

  vars = {
    app_task_name                    = "${var.task_name}-${var.env}-${var.region}"
    app_image                        = var.app_image
    app_version                      = var.app_version
    app_env                          = var.env
    app_region                       = var.region
    app_db_host                      = data.aws_rds_cluster.auroradb_cluster.endpoint
    app_db_name                      = data.aws_rds_cluster.auroradb_cluster.database_name
    app_repository_deploy_key_secret = var.repository_deploy_key_secret
    log_group                        = var.cloudwatch_log_group
    credentials                      = data.aws_secretsmanager_secret.registry_credentials.arn
  }
}

resource "aws_ecs_task_definition" "flyway_migration_task" {
  family                   = "${var.task_family_name}-${var.env}-${var.region}"
  container_definitions    = data.template_file.taskdef_template.rendered
  cpu                      = 256
  memory                   = 512
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = data.aws_iam_role.task_role.arn
  task_role_arn            = data.aws_iam_role.task_role.arn
}
