variable "region" {
  type        = string
  description = "The AWS region"
}

variable "flyway_migration_role_name" {
  type        = string
  description = "The AWS IAM role name for the Flyway Migration ECS Task"
  default     = "flyway-migration-role"
}

variable "flyway_migration_policy_name" {
  type        = string
  description = "The AWS IAM policy for the Flyway Migration IAM Role"
  default     = "flyway-migration-policy"
}
