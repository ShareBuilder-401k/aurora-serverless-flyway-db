variable "env" {
  type        = string
  description = "The AWS environment"
}

variable "region" {
  type        = string
  description = "The AWS region"
}

variable "cluster_name" {
  type        = string
  description = "The base name of the ECS Cluster"
  default     = "ecs-cluster"
}

variable "ecs_log_group_name" {
  type        = string
  description = "The name of the cloudwatch log group to create for the ECS Cluster"
  default     = "/ecs_logs"
}
