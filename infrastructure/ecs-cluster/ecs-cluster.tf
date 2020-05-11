resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.cluster_name
}

resource "aws_cloudwatch_log_group" "ecs-logs" {
  name = var.ecs_log_group_name
}
