variable "env" {
  type        = string
  description = "The AWS Environment"
}

variable "region" {
  type        = string
  description = "The AWS Region"
}

variable "vpc_name" {
  type        = string
  description = "The name of the VPC to deploy the Bastion Hosts in"
}

variable "subnet_names" {
  type        = list(string)
  description = "The list of subnet names to deploy the Bastion Hosts in"
}

variable "bastion_sg_name" {
  type        = string
  description = "The base name of the Bastion Security Group"
  default     = "bastion-sg"
}

variable "ingress_cidrs" {
  type        = list(string)
  description = "The list of cidr ranges allowed to connect to the bastion host"
}

variable "bastion_key_name" {
  type        = string
  description = "The name of the Key Pair used to connect to the Bastion Host"
  default     = "bastion-key-pair"
}

variable "bastion_public_key_file" {
  type        = string
  description = "The path to the public key file for the Bastion Key Pair"
}

variable "bastion_host_name" {
  type        = string
  description = "The base name of the Bastion Hosts"
  default     = "bastion-host"
}
