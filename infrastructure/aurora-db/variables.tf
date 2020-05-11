variable "region" {
  type        = string
  description = "The AWS region"
}

variable "vpc_name" {
  type        = string
  description = "The name of VPC to create DB in"
}

variable "subnet_names" {
  type        = list(string)
  description = "A list of subnets for the DB subnet group"
}

variable "availability_zones" {
  type        = list(string)
  description = "A list of availability zones the DB can be in"
}

variable "security_group_names" {
  type        = list(string)
  description = "An optional list of security groups to assign to the DB instance"
  default     = []
}

variable "master_credentials_secret" {
  type        = string
  description = "The name of the secret containing the credentials for the DB master user"
}

variable "db_sg_name" {
  type        = string
  description = "The name of the DB security group"
  default     = "auroradb-sg"
}

variable "db_subnet_group_name" {
  type        = string
  description = "The name of the DB subnet group to be created"
  default     = "auroradb-subnet-group"
}

variable "db_cluster_name" {
  type        = string
  description = "The name of the DB cluster"
  default     = "auroradb-cluster"
}

variable "db_name" {
  type        = string
  description = "The name for the database on the Aurora DB Cluster"
  default     = "auroradb"
}
