variable "region" {
  type        = string
  description = "The AWS region"
}

variable "vpc_name" {
  type        = string
  description = "The name of the AWS VPC to create the Flyway Fargate SG in"
}

variable "registry_token" {
  type        = string
  description = "The name of the secret containing the credentials to access the registry containing the docker image for the fargate task"
}

variable "auroradb_cluster_name" {
  type        = string
  description = "The name for the auroradb cluster"
  default     = "auroradb-cluster"
}

variable "task_name" {
  type        = string
  description = "The name of the fargate task"
  default     = "flyway-migration"
}

variable "task_family_name" {
  type        = string
  description = "The name of the fargate task family"
  default     = "flyway-migration-family"
}

variable "task_iam_role" {
  type        = string
  description = "The IAM role for the flyway fargate task. Req: kms:Decrypt, secretsmanager:GetSecretValue"
}

variable "task_sg_name" {
  type        = string
  description = "The name for the Flyway Fargate SG"
  default     = "flyway-fargate-sg"
}

variable "app_image" {
  type        = string
  description = "The docker image for the fargate task"
}

variable "app_version" {
  type        = string
  description = "The version of the docker image to use for the fargate task"
}

variable "repository_deploy_key_secret" {
  type        = string
  description = "The name of the AWS SecretsManager Secret holding the GitHub Deploy Key (SSH Key)"
}

variable "repository_owner" {
  type        = string
  description = "The owner of the git repository. Ex: sharebuilder-401k for https://github.com/sharebuilder-401k/aurora-serverless-flyway-db"
}

variable "repository_path" {
  type        = string
  description = "The path of the git repository. Ex: aurora-serverless-flyway-db for https://github.com/sharebuilder-401k/aurora-serverless-flyway-db"
}

variable "cloudwatch_log_group" {
  type        = string
  description = "The name of the cloudwatch log group to send the ecs-logs to"
  default     = "/ecs_logs"
}
